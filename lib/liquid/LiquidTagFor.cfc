<cfcomponent output="false" extends="LiquidBlock" hint="
 * Loops over an array, assigning the current value to a given variable
 * 
 * @example
 * {%for item in array%} {{item}} {%endfor%}
 * 
 * With an array of 1, 2, 3, 4, will return 1 2 3 4
 * 
 * @package Liquid
">

	<!--- The collection to loop over --->
	<cfset variables._collectionName = "">
	
	<!--- The variable name to assign collection elements to --->
	<cfset variables._variableName = "">

	<!--- The name of the loop, which is a compound of the collection and variable names --->
	<cfset variables._name = "">

	<cffunction name="init" output="false">
		<cfargument name="markup" type="string" required="true">
		<cfargument name="tokens" type="array" required="true">
		<cfargument name="file_system" type="any" required="true" hint="LiquidFileSystem">
		<cfset var loc = {}>
		
		<cfset super.init(arguments.markup, arguments.tokens, arguments.file_system)>
		
		<cfset loc.syntax_regexp = createObject("component", "LiquidRegexp").init('(\w+)\s+in\s+(#application["LiquidConfig"]["LIQUID_ALLOWED_VARIABLE_CHARS"]#+)')>
		
		<cfif loc.syntax_regexp.match(arguments.markup)>

			<cfset variables._variableName = loc.syntax_regexp.matches[2]>
			<cfset variables._collectionName = loc.syntax_regexp.matches[3]>
			<cfset variables._name = loc.syntax_regexp.matches[2] & '-' & loc.syntax_regexp.matches[3]>
			<cfset this.extract_attributes(arguments.markup)>
			
		<cfelse>
		
			<cfset createobject("component", "LiquidException").init("Syntax Error in 'for loop' - Valid syntax: for [item] in [collection]")>
			
		</cfif>
		
		<cfreturn this>
	</cffunction>
	
	<cffunction name="render" output="false">
		<cfargument name="context" type="any" required="true" hint="LiquidContext">
		<cfset var loc = {}>
		
		<cfif !IsDefined("arguments.context.registers") OR !StructKeyExists(arguments.context.registers, "for")>
			<cfset arguments.context.registers["for"] = []>
		</cfif>
		
		<cfset loc.collection = arguments.context.get(variables._collectionName)>

		<cfif !StructKeyExists(loc, "collection") OR !IsArray(loc.collection) OR ArrayIsEmpty(loc.collection)>
			<cfreturn "">
		</cfif>
		
		<!--- array(0, count($collection)) --->
		<cfif StructKeyExists(variables.attributes, "limit") OR StructKeyExists(variables.attributes, "offset")>
		
			<cfset loc.range = [ArrayLen(loc.collection), 0]>

			<cfset loc.offset = 0>
			
			<cfif StructKeyExists(variables.attributes, 'offset')>
				<cfif variables.attributes['offset'] eq "continue">
					<cfset loc.offset = arguments.context.registers['for'][variables._name]>
				<cfelse>
					<cfset loc.offset = arguments.context.get(variables.attributes['offset'])>
				</cfif>
			</cfif>
			
			<cfif StructKeyExists(variables.attributes, 'limit')>
				<cfset loc.limit = arguments.context.get(variables.attributes['limit'])>
			<cfelse>
				<cfset loc.limit = "">
			</cfif>
			
			<cfif IsNumeric(loc.limit)>
				<cfset loc.range_end = loc.limit>
			<cfelse>
				<cfset loc.range_end = ArrayLen(loc.collection) - loc.offset>
			</cfif>
			
			<cfset loc.range = [loc.offset, loc.range_end]>
			
			<cfset arguments.context.registers['for'][variables._name] = loc.range_end + loc.offset>
			
			<cfset loc.collection = createObject("java", "java.util.ArrayList").Init(loc.collection).subList(JavaCast("int", loc.range[1]), JavaCast("int", loc.range[2]))>
			
		</cfif>
		
		<cfset loc.result = "">

		<cfif ArrayIsEmpty(loc.collection)>
			<cfreturn loc.result>
		</cfif>
		
		<cfset arguments.context.push()>
		
		<cfset loc.length = ArrayLen(loc.collection)>

		<cfloop from="1" to="#loc.length#" index="loc.index">

			<cfset arguments.context.set(variables._variableName, loc.index)>
			<cfset loc.temp = {}>
			<cfset loc.temp.name = variables._name>
			<cfset loc.temp.length = loc.length>
			<cfset loc.temp.index = loc.index + 1>
			<cfset loc.temp.index0 = loc.index>
			<cfset loc.temp.rindex = loc.length - loc.index>
			<cfset loc.temp.rindex0 = loc.length - loc.index - 1>
			<cfset loc.temp.first = IIf(loc.index eq 1, de(true), de(false))>
			<cfset loc.temp.last = IIF(loc.index eq (loc.length - 1), de(true), de(false))>
			<cfset arguments.context.set('forloop', loc.temp)>

			<cfset loc.result &= this.render_all(this._nodelist, arguments.context)>
			
		</cfloop>
		
		<cfset arguments.context.pop()>
		
		<cfreturn loc.result>
	</cffunction>
	
</cfcomponent>