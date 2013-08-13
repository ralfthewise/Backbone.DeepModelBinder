class Backbone.DeepModelBinder
  _.extend(@prototype, Backbone.Events)

  @collectionRegexp = new RegExp("([^\\[]+)\\[(-?[0-9]+)\]$")

  constructor: () ->
    @topLevelModelBinder = new Backbone.ModelBinder()
    @triggers = null
    @bindingChains = {}

  bind: (model, rootEl, bindings, options) =>
    @model = model
    @rootEl = rootEl
    @bindings = bindings
    @options = options
    @_bind()

  bindCustomTriggers: (model, rootEl, triggers, attributeBindings, modelSetOptions) =>
    @triggers = triggers
    @bind(model, rootEl, attributeBindings, modelSetOptions)

  unbind: () =>
    @topLevelModelBinder.unbind()

    _.each(@bindingChains, (bindingChain, modelPath, ignored) =>
      #remove any previous bindings/listenTo
      bindingChain.modelBinder.unbind()
      #_.each(bindingChain.chainSteps, (previouslyObservedModel, path, ignored) =>
      #  @stopListening(previouslyObservedModel)
      #)
      @stopListening()
      bindingChain.chainSteps = {}
      bindingChain.bindings = {}
      bindingChain.model = null
    )
    @bindingChains = {}

  _bind: () ->
    @unbind()
    proxiedBindings = {}

    _.each(@bindings, (binding, attribute, ignored) =>
      if attribute.indexOf('.') is -1
        #nothing special about this binding, send it on to ModelBinder
        proxiedBindings[attribute] = binding

      else
        #ok it's a deep binding, let's deal with it
        @_bindDeep(attribute, binding)
    )

    #pass on our proxied bindings to the real ModelBinder
    @_proxyBind(@topLevelModelBinder, @model, proxiedBindings)

    #pass on bindings for deeply nested ModelBinders that were created from the @_bindDeep calls above
    _.each(@bindingChains, (bindingChain, modelPath, ignored) =>
      if bindingChain.model?
        @_proxyBind(bindingChain.modelBinder, bindingChain.model, bindingChain.bindings)
    )

  #attribute = 'post.comments[1].author.name', binding = <typical ModelBinder binding>
  _bindDeep: (attribute, binding) ->
    #get the 'post.comments[1].author' part of 'post.comments[1].author.name'
    nestedModelPath = attribute.substring(0, attribute.lastIndexOf('.'))

    #construct our meta object to track model, ModelBinder, bindings and chainSteps
    #  model: the leaf model being monitored by ModelBinder (ex: 'post.comments[1].author' model)
    #  modelBinder: the actual ModelBinder that is monitoring the leaf model
    #  bindings: the bindings that are passed on to the ModelBinder for the leaf elements of this model
    #    (ex: bindings 'post.comments[1].author.name' and 'post.comments[1].author.email' would have 2 bindings, 1 for 'name' and 'email')
    #  chainSteps: an array of Backbone.Models representing each step in the chain that are monitored
    #    (ex: 'post.comments[1].author.name' would have 3 models in this array - one for 'post', 'comments[1]', and 'author')
    @bindingChains[nestedModelPath] ?= {model: null, modelBinder: (new Backbone.ModelBinder()), bindings: {}, chainSteps: {}}
    bindingChain = @bindingChains[nestedModelPath]

    #allright, now let's loop through each part of the chain
    attributeParts = attribute.split('.')
    currentAttributePath = null
    currentBackboneObject = @model
    _.each(attributeParts, (attributePart, index, ignored) =>
      if currentBackboneObject? #stop if we encounter null/undefined in the chain (could be model/collection that hasn't been fetched yet)
        @_validateBackboneModel(currentBackboneObject)

        if (collectionMatch = @constructor.collectionRegexp.exec(attributePart))
          #ok we're dealing with a collection index step (ex: 'post.comments[1]'), let's break it into its parts
          attributeCollectionPart = collectionMatch[1] #ex: 'comments'
          attributeCollectionIndex = Number(collectionMatch[2]) #ex: 1

          currentAttributePath += '.' if currentAttributePath?
          currentAttributePath += attributeCollectionPart
          #now let's make sure to listen if this step (comments collection) in the chain changes (ie: replaced with a different collection)
          #  nestedModelPath = 'post.comments[1].author', currentAttributePath = 'post.comments', currentBackboneObject = <post model>, attributeCollectionPart = 'comments'
          bindingChain.chainSteps[currentAttributePath] = currentBackboneObject
          @listenTo(currentBackboneObject, "change:#{attributeCollectionPart}", @_bind)

          currentBackboneObject = currentBackboneObject.get(attributeCollectionPart)
          if currentBackboneObject?
            @_validateBackboneCollection(currentBackboneObject)

            currentAttributePath += "[#{attributeCollectionIndex}]"
            #now let's make sure to listen if this step (comment within the collection) in the chain changes (ie: the index/order of comments changes)
            #  nestedModelPath = 'post.comments[1].author', currentAttributePath = 'post.comments[1]', currentBackboneObject = <comments collection>, attributeCollectionIndex = 1
            bindingChain.chainSteps[currentAttributePath] = currentBackboneObject
            @listenTo(currentBackboneObject, 'add remove reset sort', @_bind)
            realIndex = (if attributeCollectionIndex < 0 then (currentBackboneObject.length + attributeCollectionIndex) else attributeCollectionIndex) #allow negative indexes
            currentBackboneObject = currentBackboneObject.at(realIndex)

        else
          #we're dealing with just a model or leaf step (ex: 'post.comments[1].author' or 'post.comments[1].author.name')

          if index is (attributeParts.length - 1)
            #we're at the end/leaf (ex: 'post.comments[1].author.name'), let's bind this shit and be done with it
            #  nestedModelPath = 'post.comments[1].author', attributePart = 'name', currentBackboneObject = <author model>, binding = <what was passed in>
            bindingChain.model = currentBackboneObject
            bindingChain.bindings[attributePart] = binding

          else
            #add to our currentAttributePath
            currentAttributePath += '.' if currentAttributePath?
            currentAttributePath += attributePart

            #ok we're not at the end of the chain yet (ex: 'post.comments[1].author'), first things first let's
            #listen for changes at this step in the chain
            #  nestedModelPath = 'post.comments[1].author', currentAttributePath = 'post.comments[1].author', currentBackboneObject = <comment model>, attributePart = 'author'
            bindingChain.chainSteps[currentAttributePath] = currentBackboneObject
            @listenTo(currentBackboneObject, "change:#{attributePart}", @_bind)

            #now let's get the next step in the chain and see if we can continue binding to it
            currentBackboneObject = currentBackboneObject.get(attributePart)
    )

  _validateBackboneModel: (backboneObject) ->
    unless (backboneObject instanceof Backbone.Model)
      throw new Error('Deeply bound objects must inherit from Backbone.Model')

  _validateBackboneCollection: (backboneObject) ->
    unless (backboneObject instanceof Backbone.Collection)
      throw new Error('Deeply bound objects must inherit from Backbone.Collection')

  _proxyBind: (modelBinder, model, bindings) ->
    if @triggers?
      modelBinder.bindCustomTriggers(model, @rootEl, @triggers, bindings, @options)
    else
      modelBinder.bind(model, @rootEl, bindings, @options)
