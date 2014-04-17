// Generated by CoffeeScript 1.6.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Backbone.DeepModelBinder = (function() {
    _.extend(DeepModelBinder.prototype, Backbone.Events);

    DeepModelBinder.collectionRegexp = new RegExp("([^\\[]+)\\[(-?[0-9]+)\]$");

    function DeepModelBinder() {
      this.unbind = __bind(this.unbind, this);
      this.bindCustomTriggers = __bind(this.bindCustomTriggers, this);
      this.bind = __bind(this.bind, this);
      this.topLevelModelBinder = new Backbone.ModelBinder();
      this.triggers = null;
      this.bindingChains = {};
    }

    DeepModelBinder.prototype.bind = function(model, rootEl, bindings, options) {
      this.model = model;
      this.rootEl = rootEl;
      this.bindings = bindings;
      this.options = options;
      return this._bind();
    };

    DeepModelBinder.prototype.bindCustomTriggers = function(model, rootEl, triggers, attributeBindings, modelSetOptions) {
      this.triggers = triggers;
      return this.bind(model, rootEl, attributeBindings, modelSetOptions);
    };

    DeepModelBinder.prototype.unbind = function() {
      var _this = this;
      this.topLevelModelBinder.unbind();
      _.each(this.bindingChains, function(bindingChain, modelPath, ignored) {
        bindingChain.modelBinder.unbind();
        _this.stopListening();
        bindingChain.chainSteps = {};
        bindingChain.bindings = {};
        return bindingChain.model = null;
      });
      return this.bindingChains = {};
    };

    DeepModelBinder.prototype._bind = function() {
      var proxiedBindings,
        _this = this;
      this.unbind();
      proxiedBindings = {};
      _.each(this.bindings, function(binding, attribute, ignored) {
        if (attribute.indexOf('.') === -1) {
          return proxiedBindings[attribute] = binding;
        } else {
          return _this._bindDeep(attribute, binding);
        }
      });
      this._proxyBind(this.topLevelModelBinder, this.model, proxiedBindings);
      return _.each(this.bindingChains, function(bindingChain, modelPath, ignored) {
        if (bindingChain.model != null) {
          return _this._proxyBind(bindingChain.modelBinder, bindingChain.model, bindingChain.bindings);
        }
      });
    };

    DeepModelBinder.prototype._bindDeep = function(attribute, binding) {
      var attributeParts, bindingChain, currentAttributePath, currentBackboneObject, nestedModelPath, _base,
        _this = this;
      nestedModelPath = attribute.substring(0, attribute.lastIndexOf('.'));
      if ((_base = this.bindingChains)[nestedModelPath] == null) {
        _base[nestedModelPath] = {
          model: null,
          modelBinder: new Backbone.ModelBinder(),
          bindings: {},
          chainSteps: {}
        };
      }
      bindingChain = this.bindingChains[nestedModelPath];
      attributeParts = attribute.split('.');
      currentAttributePath = '';
      currentBackboneObject = this.model;
      return _.each(attributeParts, function(attributePart, index, ignored) {
        var attributeCollectionIndex, attributeCollectionPart, collectionMatch, realIndex;
        if (currentBackboneObject != null) {
          _this._validateBackboneModel(currentBackboneObject);
          if ((collectionMatch = _this.constructor.collectionRegexp.exec(attributePart))) {
            attributeCollectionPart = collectionMatch[1];
            attributeCollectionIndex = Number(collectionMatch[2]);
            if (currentAttributePath.length > 0) {
              currentAttributePath += '.';
            }
            currentAttributePath += attributeCollectionPart;
            bindingChain.chainSteps[currentAttributePath] = currentBackboneObject;
            _this.listenTo(currentBackboneObject, "change:" + attributeCollectionPart, _this._bind);
            currentBackboneObject = currentBackboneObject.get(attributeCollectionPart);
            if (currentBackboneObject != null) {
              _this._validateBackboneCollection(currentBackboneObject);
              currentAttributePath += "[" + attributeCollectionIndex + "]";
              bindingChain.chainSteps[currentAttributePath] = currentBackboneObject;
              _this.listenTo(currentBackboneObject, 'add remove reset sort', _this._bind);
              realIndex = (attributeCollectionIndex < 0 ? currentBackboneObject.length + attributeCollectionIndex : attributeCollectionIndex);
              return currentBackboneObject = currentBackboneObject.at(realIndex);
            }
          } else {
            if (index === (attributeParts.length - 1)) {
              bindingChain.attributePathIsComplete = true;
              bindingChain.model = currentBackboneObject;
              return bindingChain.bindings[attributePart] = binding;
            } else {
              if (currentAttributePath.length > 0) {
                currentAttributePath += '.';
              }
              currentAttributePath += attributePart;
              bindingChain.chainSteps[currentAttributePath] = currentBackboneObject;
              _this.listenTo(currentBackboneObject, "change:" + attributePart, _this._bind);
              return currentBackboneObject = currentBackboneObject.get(attributePart);
            }
          }
        } else {
          if (bindingChain.attributePathIsComplete !== false) {
            bindingChain.attributePathIsComplete = false;
            bindingChain.model = new Backbone.Model();
          }
          if (index === (attributeParts.length - 1)) {
            return bindingChain.bindings[attributePart] = binding;
          }
        }
      });
    };

    DeepModelBinder.prototype._validateBackboneModel = function(backboneObject) {
      if (!(backboneObject instanceof Backbone.Model)) {
        throw new Error('Deeply bound objects must inherit from Backbone.Model');
      }
    };

    DeepModelBinder.prototype._validateBackboneCollection = function(backboneObject) {
      if (!(backboneObject instanceof Backbone.Collection)) {
        throw new Error('Deeply bound objects must inherit from Backbone.Collection');
      }
    };

    DeepModelBinder.prototype._proxyBind = function(modelBinder, model, bindings) {
      if (this.triggers != null) {
        return modelBinder.bindCustomTriggers(model, this.rootEl, this.triggers, bindings, this.options);
      } else {
        return modelBinder.bind(model, this.rootEl, bindings, this.options);
      }
    };

    return DeepModelBinder;

  })();

}).call(this);
