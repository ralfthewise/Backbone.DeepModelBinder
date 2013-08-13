Backbone.DeepModelBinder
========================

Extension of Backbone.ModelBinder to support binding of nested/related Backbone models/collections

Examples
--------

    model = constructSomeNestedBackboneModel();
    binder = new Backbone.DeepModelBinder();
    el = $('#some-el');

    binder.bind(model, el, {'post.title': '.post-title'});
    binder.bind(model, el, {'post.comments[0].author.name': '.first-comment-author'});
    binder.bind(model, el, {'post.comments[-1].author.email': '.last-comment-author-email'});

    modelBinderTriggers = {
      '': 'change hiddenchange',
      '[contenteditable]': 'blur'
    }
    binder.bindCustomTriggers(model, el, modelBinderTriggers, {'post.title': '.post-title'});
