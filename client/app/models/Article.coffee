Prototype = require("models/Prototype")

class Article extends Prototype
	init: (json) -> 	
		console.log json
		json ?= {}
		@name = json.name || null
		@_dis = json.DI || null
		@_des = json.DE || null
		@_funcs = json.FUNC || null
		article = require("views/article")(@)
		section = document.body.getElementsByTagName "section"
		section = section[0]
		section.innerHTML = section.innerHTML + article
		@inputs = {}
		for key, di of @_dis
			@inputs[key] = document.getElementById(@name + ":" + key)
			@inputs[key].onchange = @checkValues

		@outputs = {}
		@outputs[key] = document.getElementById(@name + ":" + key) for key, de of @_des
		@_funcs[f] = eval(@_funcs[f]) for f of @_funcs
		return @

	checkValues: () -> 
		invalid = false
		invalid = true for key, input of @inputs when not input.value
		unless invalid
			@calculateDES()	

	calculateDES: () ->			
		for de, output of @outputs
			valueSet = {}
			valueSet[key] = o.value for key, o of @inputs
			valueSet[key] = f for key, f of @_funcs
			output.value = @_funcs["_" + de].call(valueSet)
	
		
module.exports = Article
module.exports.reuse = Object.create Article