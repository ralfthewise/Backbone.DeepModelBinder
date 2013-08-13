Backbone.DeepModelBinder
========================

Extension of [Backbone.ModelBinder](https://github.com/theironcook/Backbone.ModelBinder) to support binding of
nested/related Backbone models/collections.  Meant to be API compatible with Backbone.ModelBinder so it can be
used as a drop in replacements.  Mirrored methods are:

    bind(model, rootEl, attributeBindings, modelSetOptions)
    bindCustomTriggers(model, rootEl, triggers, attributeBindings, modelSetOptions)
    unbind()
    

Examples
--------

    var model = constructNestedBackboneModel();
    var binder = new Backbone.DeepModelBinder();
    var el = $('#some-el');

    binder.bind(model, el, {'post.title': '.post-title'});
    binder.bind(model, el, {'post.comments[0].author.name': '.first-comment-author'});
    binder.bind(model, el, {'post.comments[-1].author.email': '.last-comment-author-email'});

    var modelBinderTriggers = {
      '': 'change hiddenchange',
      '[contenteditable]': 'blur'
    };
    binder.bindCustomTriggers(model, el, modelBinderTriggers, {'post.title': '.post-title'});

    
    
    var constructNestedBackboneModel = function() {
      model = new Backbone.Model({type: 'blog_post', publish_date: new Date()});
      post = new Backbone.Model({title: 'My Awesome Blog Post'});
      comments = new Backbone.Collection();
      comment = new Backbone.Model({text: 'some silly comment'});
      author = new Backbone.Model({name: 'ralfthewise', email: 'ralfthewise@gmail.com'});
    
      //setup the nesting
      comment.set({author: author});
      comments.add(comment);
      post.set({comments: comments});
      model.set({post: post});
    
      return model;
    }
