NH ?= {}
NH.IO ?= {}
NH =
  init: ->
      console.profile "InitProfile"
      CL.Framework.init ->
        CL.DynamicFileLoader.addLib
          name: "screen"
          location: "/css/screen.css"
          media: "all"

        CL.DynamicFileLoader.addLib
          name: "io"
          location: "/socket.io/socket.io.js"

        CL.DynamicFileLoader.processQueue ->
          NH.IO = io.connect("http://localhost:8080/")
          console.log NH.IO
          document.body.innerHTML = ""
          NH.screenContainer = document.createElement("section")
          NH.IO.on "errorLog", NH.errorLog
          NH.IO.on "successLog", NH.successLog
          NH.IO.on "getSnippet", NH.getSnippet
          document.body.appendChild NH.screenContainer
          NH.menu = document.createElement("aside")
          NH.menu.appendChild NH.createMenu(NH._menu, "Main Menu")
          document.body.appendChild NH.menu
          CL.LightBox.reuse("getSnippet", "Type the name of the snippet", ->
            NH.requestSnippetFunc CL.LightBox.reuse("getSnippet").controlls["name"].element.value
          ).addController("Input",
            id: "name"
          ).addController "Submit",
            value: "Try"

          CL.LightBox.reuse("getSnippetViaUpload", "Point to your JSON", ->
            files = CL.LightBox.reuse("getSnippetViaUpload").controlls["source"].element.files
            for file of files
              reader = new FileReader
              reader.onload = (e) ->
                NH.getSnippet JSON.parse(e.target.result)
            reader.readAsText files[0]
          ).addController("FileInput",
            id: "source"
          ).addController "Submit",
            value: "Try"

          CL.LightBox.reuse("errorLog", "Ooops, error ... ").addController "Description",
            id: "descr"

          CL.LightBox.reuse("successLog", "Chimpy sais it works!").addController "Description",
            id: "descr"

          CL.LightBox.reuse("formulaeModal", "Point to your JSON", ->
            NH.parseFormulae CL.LightBox.reuse("formulaeModal").controlls['input'].element.value
            CL.LightBox.reuse("formulaeModal").hide(5)
          ).addController("Input",
            id: "input"
          )

          b = document.body
          h = document.createElement("div")
          draggingInline = false
          persistentOffset = [ 0, 0 ]

          b.addEventListener "dragenter", (e) ->
            h.style.display = "block"
            h.style.opacity = 1
            e.preventDefault()
            e.stopPropagation()

          b.addEventListener "dragover", (e) ->
            unless draggingInline
              e.dataTransfer.dropEffect = "copy"
              h.style.display = "block"
              h.style.opacity = 1
            e.preventDefault()
            e.stopPropagation()

          b.addEventListener "dragend", (e) ->
            h.style.display = "none"
            h.style.opacity = 0
            if draggingInline
              e.target.style.top = e.pageY - persistentOffset[1] + "px"
              e.target.style.left = e.pageX - persistentOffset[0] + "px"
              persistentOffset = [ 0, 0 ]
              draggingInline = false
            e.preventDefault()
            e.stopPropagation()

          b.addEventListener "drop", (event) ->
            files = event.dataTransfer.files
            for file of files
              reader = new FileReader()
              reader.onload = (e) ->
                el = NH.getSnippet(JSON.parse(e.target.result))
                el = el.wrapper
                el.style.top = event.pageY - 175 + "px"
                el.style.left = event.pageX - 100 + "px"

              reader.readAsText files[file]
            h.style.display = "none"
            h.style.opacity = 0
            event.preventDefault()
            event.stopPropagation()

          b.addEventListener "dragstart", (e) ->
            draggingInline = true
            x = parseInt(e.target.style.left)
            x = (if x then x else 0)
            y = parseInt(e.target.style.top)
            y = (if y then y else 0)
            persistentOffset = [ e.pageX - x, e.pageY - y ]

          h.setAttribute "style", "position: absolute;" + "left: 0;" + "right: 0;" + "top: 0;" + "bottom: 0;" + "background: rgba(0, 0, 0, 0.8);" + "content: \"Drop Here\";" + "text-align: center;" + "vertical-align: center;" + "line-hight: 100%;" + "display: none;" + "opacity: 0;" + "-webkit-transition: all 0.5s ease-in-out;" + "font-size: 21pt;" + "color: white;" + "z-index: 10;"
          document.body.appendChild h
          console.profileEnd()

  errorLog: (data, time) ->
    NH.log "errorLog", data, time

  successLog: (data, time) ->
    NH.log "successLog", data, time

  log: (which, data, time) ->
    time = (if time then time else 1500)
    CL.LightBox.reuse(which).setProperty("descr", "value", data).show(5).schedule "hide", time, 5

  parseFormulae: (string) ->
    functions = [
      "sqrt",
      "pow",
      "PI"
    ]
    json = {}
    json.name = "Formulae"
    json.descr = "Fast input formulae"
    ls = (string.substr 0, string.indexOf("=") - 1).replace(" ", "")
    json.DE = {}
    json.DE[ls] = ls
    json.DI = {}
    f = ""
    rs = (string.substr string.indexOf("=") + 1).replace(/[ ]/g, "")
    rs = rs.replace(/[\+]/g, " + ").replace(/[\/]/g, " / ").replace(/[-]/g, " - ").replace(/[\*]/g, " * ").replace("{", "(").replace("[", "(").replace("}", ")").replace("]", ")").replace(/[\(]/g, " ( ").replace(/[\)]/g, " ) ").replace(/[,]/g, " , ")
    console.log rs
    rs = rs.split(" ")
    console.log json , rs
    for r in rs
      if not r then continue
      if not /[\+\*\/-]/g.test(r)
        v = null
        di = null
        for func in functions
          index = r.indexOf func
          if index isnt -1 
            v = index
            break
        
        console.log v, r
        if v?
          r = r.substr(0, v) + "Math." + r.substr(v) 
        else if /[a-zA-Z][a-zA-Z0-9]*/g.test(r)
          di = r
          r = "this." + r
          json.DI[di] = di if di

      f = f + r
    
    json.FUNC = {}
    json.FUNC["_" + ls] = "(function(){ console.log(\""+f+"\"); return " + f + "; })"
    console.log NH.getSnippet json

  getSnippet: (data) ->
    NH.articles[NH.articleHead] = NH.createArticle(NH.articleHead)
    NH.screenContainer.appendChild NH.articles[NH.articleHead].wrapper
    NH.articles[NH.articleHead].assembleSnippet data
    CL.LightBox.reuse("getSnippet").hide 5
    CL.LightBox.reuse("getSnippetViaUpload").hide 5
    NH.articles[NH.articleHead++]

  requestSnippet: (mode) ->
    mode = (if mode then mode else "classic")
    if mode is "classic"
      CL.LightBox.reuse("getSnippet").show 5
    else
      CL.LightBox.reuse("getSnippetViaUpload").show 5

  requestSnippetFunc: (name) ->
    NH.IO.emit "requestSnippet",
      name: name

  articles: []
  articleHead: 0
  createMenu: (json, title) ->
    a = document.createElement("article")
    e = document.createElement("h2")
    u = document.createElement("ul")
    e.innerHTML = title
    a.appendChild e
    for o of json
      if typeof json[o] isnt "object"
        el = document.createElement("li")
        el.innerHTML = o
        el.onclick = json[o]
      else
        el = NH.createMenu json[o], o
      u.appendChild el
    a.appendChild u
    a

  _menu:
    Options:
      Account: NH["null"]
      Logout: NH["null"]

    Search:
      Tags: NH["null"]

    "My Snippets":
      "Upload Snippet": ->
        NH.requestSnippet "upload"

      "Get Snippet By Name": ->
        NH.requestSnippet()

      "Quick Formulae": ->
        CL.LightBox.reuse("formulaeModal").show 5

      "List stored snippets": ->
        NH.IO.emit "requestSnippetList"

  _articlePrototype: (id) ->
    @_id = id
    @wrapper = document.createElement("article")
    @title = document.createElement("h1")
    @container = document.createElement("section")
    @wrapper.appendChild @title
    @wrapper.appendChild @container
    @options = document.createElement("div")
    @options.className = "snippetOptions"
    @closeButton = document.createElement("span")
    @closeButton.className = "close optionButton"
    @closeButton.innerHTML = "CLOSE"
    @closeButton.onclick = =>
      @remove()
    @saveButton = document.createElement("span")
    @saveButton.className = "save optionButton"
    @saveButton.innerHTML = "SAVE"
    @saveButton.onclick = =>
      NH.IO.emit "requestSnippetSave", @json
      @remove()
    @options.appendChild @closeButton
    @options.appendChild @saveButton
    @wrapper.appendChild @options
    @wrapper.draggable = true
    this

  null: ->
    null

  screenContainer: null
  createArticle: (id) ->
    new NH._articlePrototype(id)

  removeArticle: (id) ->
    @articles[id] = null
    @articles.splice id, 1
    @articleHead--

window.onload = NH.init
NH._articlePrototype::assembleSnippet = (data) ->
  @title.innerHTML = data.name
  @json = data
  @dis = {}
  @_di = {}
  @des = {}
  @_de = {}
  @lbls = {}
  @_funcs = {}
  @description = data.descr
  if data._id
    @saveButton.innerHTML = "DELETE"
    @saveButton.onclick = =>
      NH.IO.emit "requestSnippetRemove", data._id
      @remove()
  for s of data.DI
    @_di[s] = s
    @dis[s] = document.createElement("input")
    @lbls[s] = document.createElement("label")
    @lbls[s]["for"] = s
    @lbls[s].innerHTML = data.DI[s]
    @container.appendChild @lbls[s]
    @dis[s].id = s
    @dis[s].onchange = @_checkValues.bind(this)
    @container.appendChild @dis[s]
  s = document.createElement("span")
  s.className = "sectionSeparator"
  @container.appendChild s
  for s of data.DE
    @_de[s] = data.DE._de
    @des[s] = document.createElement("input")
    @des[s].id = s
    @lbls[s] = document.createElement("label")
    @lbls[s]["for"] = s
    @lbls[s].innerHTML = data.DE[s]
    @container.appendChild @lbls[s]
    @des[s].readonly = "readonly"
    @container.appendChild @des[s]
  for f of data.FUNC
    @_funcs[f] = eval("(" + data.FUNC[f] + ")")

NH._articlePrototype::remove = ->
  @wrapper.parentNode.removeChild @wrapper
  NH.removeArticle @_id

NH._articlePrototype::_checkValues = ->
  r = true
  for d of @dis
    r = false  if @dis[d].value is ""
  if r
    @_calculateDES()
  else
    false

NH._articlePrototype::_calculateDES = ->
  for d of @des
    valueSet = {}
    for i of @dis
      valueSet[i] = @dis[i].value
    for i of @_funcs
      valueSet[i] = @_funcs[i]
    @des[d].value = @_funcs["_" + d].call(valueSet)

exports = this
exports.NH = NH
exports.NH.IO = NH.IO

console.log "Loaded the application!"
