/*
---
description: Simple overlay class for MooTools.
license: MIT-style
authors: [Christopher Pitt]
provides: [Overlay]
requires: 
  core/1.2.4: [Fx.Morph]
...
*/

(function(context) {

	var z, Overlay = new Class({
		'Implements': [Options, Events],
		'options': {    
			/*
			'onLoad': $empty,
			'onPosition': $empty,
			'onShow': $empty,
			'onHide': $empty,
			'onClick': $empty,
			'container': false,
			*/        
			'color': '#000',
			'opacity': 0.7,
			'zIndex': 1,
			'duration': 100
		},

		'initialize': function(options)
		{
			this.setOptions(options);
			z = this.options.zIndex;

			var self = this,
				container = document.id(self.options.container || document.body),

				wrapper = new Element('div', {
					'styles': {
						'position': 'absolute',
						'left': 0,
						'top': 0,
						'visibility': 'hidden',
						'overflow': 'hidden',
						'z-index': z++,
						'border': 'none',
						'padding': 0,
						'margin': 0
					},
					'events': {
						'click': function(e)
						{
							self.fireEvent('click', [e]);
						}
					}
				}).inject(container),

				iframe = new Element('iframe', {
					'src': 'about:blank',
					'frameborder': 1,
					'scrolling': 'no',
					'styles': {
						'position': 'absolute',
						'top': 0,
						'left': 0,
						'width': '100%',
						'height': '100%',
						'opacity': 0,
						'z-index': z++
					}
				}).inject(wrapper),

				overlay = new Element('div', {
					'styles': {
						'position': 'absolute',
						'left': 0,
						'top': 0,
						'width': '100%',
						'height': '100%',
						'background-color': self.options.color,
						'z-index': z++,
						'border': 'none',
						'padding': 0,
						'margin': 0
					}
				}).inject(wrapper),

				morph = new Fx.Morph(wrapper, {
					'duration': self.options.duration
				});

			self.container = container;
			self.wrapper = wrapper;
			self.iframe = iframe;
			self.overlay = overlay;
			self.morph = morph;

			container.addEvents({
				'resize': self.position.bind(self),
				'scroll': self.position.bind(self)
			});

			this.fireEvent('onLoad');
		},

		'position': function()
		{
			var size;

			if(this.options.container == document.body)
			{
				size = document.id(document.body).getScrollSize();
			}
			else
			{
				size = document.id(this.container).getScrollSize();
			}

			this.wrapper.setStyles({
				'width': size.x,
				'height': size.y
			});

			this.fireEvent('onPosition');
		},

		'show': function()
		{
			this.position();
			this.overlay.setStyle('display', 'block');

			this.morph.start({
				'opacity': [0, this.options.opacity]
			});

			this.fireEvent('onShow');
		},

		'hide': function()
		{
			this.overlay.setStyle('display', 'none');

			this.morph.start({
				'opacity': [this.options.opacity, 0]
			});

			this.fireEvent('onHide');
		}
	});

	context.Overlay = Overlay;

})(window ? window : this);