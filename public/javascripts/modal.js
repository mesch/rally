/*
---
description: Simple modal class (with overlay) for MooTools.
license: MIT-style
authors: [Christopher Pitt]
provides: [Modal]
requires: 
  Overlay (sixtyseconds)/0.1: [Overlay]
...
*/

(function(context) {

	var z, Modal = new Class({
		'Implements': [Options, Events],

		'options': {    
			/*
			'onLoad': $empty,
			'onPosition': $empty,
			'onShow': $empty,
			'onHide': $empty,
			'onButton': $empty,
			*/
			'zIndex': 1,
			'buttons': 'ok|cancel',
			'duration': 100,
			'color': '#000',
			'opacity': 0.7,
			'modal_id' : null,
			'content_id' : null
		},

		'initialize': function(options)
		{
			this.setOptions(options);
			z = this.options.zIndex;

			var self = this,
				buttons = self.options.buttons.split('|'),

				overlay = new Overlay($extend(self.options, {
					'onPosition': self.position.bind(self)
				})),

				win = new Element('div', {
					'id' : this.options.modal_id,
					'class': 'modal-window',
					'styles': {
						'z-index': z++,
						'position': 'absolute',
						'display': 'none'
					}
				}).inject(document.id(self.options.container || document.body)),

				content = document.id(self.options.content) || new Element('div', 
					{
						'class': 'modal-content', 
						'id' : self.options.content_id
					});

				content.setStyles({
					'z-index': z++
				}).inject(win);            

				Array.each(buttons, function(button) {
					new Element('a', {
						'class': 'button ' + button,
						'text': button,
						'href': '#',
						'events': {
							'click': function(e)
							{
								self.fireEvent('button', [e, button]);
							}
						}
					}).inject(win);
				});

			self.overlay = overlay;
			self.win = win;
			self.content = content;

			self.fireEvent('load');
		},

		'show': function()
		{
			this.overlay.show();
			this.win.setStyle('display', 'block');
			this.fireEvent('show');
		},

		'hide': function()
		{
			this.overlay.hide();
			this.win.setStyle('display', 'none');
			this.fireEvent('hide');
		},

		'position': function()
		{
			var size = context.getSize(),
				coords = this.win
					.setStyle('display', 'block')
					.getCoordinates();

			this.win.setStyles({
				'top': Math.floor((size.y - coords.height) / 2),
				'left': Math.floor((size.x - coords.width) / 2)
			});

			this.fireEvent('position');
		}
	});

	context.Modal = Modal;

})(window ? window : this);