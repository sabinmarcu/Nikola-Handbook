moduleKeywords = ['extended', 'included']

class Prototype
	fn: @::
	@reccords = {}
	@head = 0
	@get = (which) -> @reccords[which] ?= null
	@delete = (which) -> "Nu inca"
	@create: (id, args...) -> 
		idp = id || @head
		args ?= {}
		console.log args
		args.unshift {"id": idp}
		console.log args 
		@reccords[@head] = new @__proto__ args
		@reccords[id] = @reccords[@head] if id?
		@reccords[@head++]

	@reuse: (which, args) -> 
		return @create(which, args) unless @reccords[which] 
		@get(which)


	@extend: (obj) =>
		@[key] = value for key, value of obj when key not in moduleKeywords
		obj.extended?.apply(@)
		this

	@include: (obj) =>
		@::[key] = value for key, value of obj when key not in moduleKeywords
		obj.included?.apply(@)
		this

	constructor: (args) ->
		valueSet = []
		console.log set, key, value for key, value of set for set in args
		console.log valueSet
		@init.apply @, valueSet

module.exports = Prototype
module.exports.reuse = Object.create Prototype