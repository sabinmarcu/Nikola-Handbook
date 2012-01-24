class ArticlePrototype
	constructor: (@_id) ->
		@name = "Test"
		@_dis = {
			"a": "de intrare",
			"b": "tot de intrare"
		}
		@_des = {
			"c": "de iesire"
		}
		@_funcs = {
			"_c" : "(function(){ return this.a * this.b })"
		}
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
		console.log @outputs, @inputs, @_funcs
		return @

	checkValues: () =>
		invalid = false
		invalid = true for key, input of @inputs when not input.value
		unless invalid
			@calculateDES()	

	calculateDES: () =>
		for de, output of @outputs
			valueSet = {}
			valueSet[key] = o.value for key, o of @inputs
			valueSet[key] = f for key, f of @_funcs
			output.value = @_funcs["_" + de].call(valueSet)

module.exports = new ArticlePrototype