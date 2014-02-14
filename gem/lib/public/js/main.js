$(document).ready(function(){
    var checkboxes = $('input[type=checkbox]');
    checkboxes.on('click', function(){
        var $this = $(this);
        var linked = null;
        ($this.is(":checked")) ? linked = 1 : linked = 0;
        console.log($this);
        id = parseInt($this.attr('id'));
        console.log("ID: " + id + " Linked: " + linked);
        $.ajax({
           url: '/link/'+ id +'/' + linked,
           method: 'post',
           success: function(response){
               console.log(response);
           }
        });
    });
});



