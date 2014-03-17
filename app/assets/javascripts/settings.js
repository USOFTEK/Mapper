function Settings(form, options) {
    var self = this;
    this.form = form;
    this.init = function() {
        var defaults = {env: 'production', split_sign: '/'};
        this.options = $.extend(defaults, options);
        this.submit = this.form.find('input[type=submit]').hide();
        
        this.submit.on('click', function(e){
            e.preventDefault();
            console.log(self.form.find('input[data-value]').length);
            self.form.find('input[data-value]').each(function(){
               var $this = $(this);
               if($this.val() === $this.attr('data-value'))self.reset($this);
            });
            (self.form.find('input[data-value]').length) ? self.form.submit() : self.reset_button.click();
        });
        
        this.reset_button = this.form.find($('#reset')).on('click', function() {
            self.return_default_values();
            self.submit.hide();
            $(this).hide();
        }).hide();
        this.form.find(this.options.env + ' *').off().on('click', function(e) {
            e.stopPropagation();
            var el = $(this);
            if (el.is('input') || el.has('input').length) {
                return false;
            }
            var path = self.get_path(el);
            console.log(path);
            self.change_with_input(el, path, function() {
                this.submit.show();
                this.reset_button.show();
            });
        });
    };
    this.get_path = function(el) {
        var parents = el.parentsUntil(this.form),
                node = el.clone(),
                path = [];
        node.add(parents.clone()).each(function() {
            path.push($(this)[0].tagName.toLowerCase());
        });
        return path.join(this.options.split_sign);
    };
    this.reset = function(input) {
        var val = input.data('value');
        input.parent().text(val);
        input.remove();
    };
    this.return_default_values = function() {
        this.form.find('input[data-value]').each(function() {
            var $this = $(this);
            self.reset($this);
        });
    };
    this.change_with_input = function(el, path, callback) {
        var value = el.text();
        var input = $('<input />', {value: value, name: path}).attr('data-value', value);
        el.empty().append(input);
        if (callback)
            callback.call(this);
    };
    this.init();
}
;
