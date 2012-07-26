<%= erb 'js/lib/jquery.min.js' %>
<%= erb 'js/lib/jquery-ui.min.js' %>
<%= erb 'js/lib/jquery.jqplot.min.js' %>
<%= erb 'js/lib/jqplot.barRenderer.min.js' %>
<%= erb 'js/lib/jqplot.pieRenderer.min.js' %>
<%= erb 'js/lib/jqplot.cursor.min.js' %>
<%= erb 'js/lib/jqplot.categoryAxisRenderer.min.js' %>
<%= erb 'js/lib/jqplot.pointLabels.min.js' %>


$.expr[':'].icontains = function(obj, index, meta, stack){
    return (obj.textContent || obj.innerText || jQuery(obj).text() || '').
        toLowerCase().indexOf(meta[3].toLowerCase()) >= 0;
};

<%= erb 'js/helpers.js' %>

var email_address;

jQuery(function ($) {

    tabs = function (options) {

        var defaults = {
            selector: '.tabs',
            selectedClass: 'selected'
        };

        if (typeof options == 'string') defaults.selector = options;
        var options = $.extend(defaults, options);

        return $(options.selector).each(function () {

            var obj = this;
            var targets = Array();

            function show(i) {
                $.each(targets, function (index, value) {
                    $(value).hide();
                })
                $(targets[i]).fadeIn('fast');
                $(obj).children().removeClass(options.selectedClass);
                selected = $(obj).children().get(i);
                $(selected).addClass(options.selectedClass);
            };

            $('a', this).each(function (i) {
                targets.push($(this).attr('href'));
                $(this).click(function (e) {
                    e.preventDefault();
                    show(i);
                });
            });

            show(0);

        });
    }

    tabs('nav ul');

    $("#summary-tabs").tabs();
    $("#issue-tabs").tabs();
    $("#untrusted-tabs").tabs();
    $("#plugin-tabs").tabs();
    $("#plugin-meta-tabs").tabs();
    $("#sitemap-tabs").tabs();
    $("#configuration-tabs").tabs();

    <%= erb 'js/charts.js', { :graph_data => graph_data } %>

});
