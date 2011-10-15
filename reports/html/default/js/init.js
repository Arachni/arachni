<%= erb 'js/jquery.min.js' %>
<%= erb 'js/jquery-ui.min.js' %>
<%= erb 'js/highcharts.js' %>
<%= erb 'js/highcharts-exporting.js' %>

$.expr[':'].icontains = function(obj, index, meta, stack){
    return (obj.textContent || obj.innerText || jQuery(obj).text() || '').toLowerCase().indexOf(meta[3].toLowerCase()) >= 0;
};

var configuration = <%= js_multiline(conf) %>
var email_address;

var $warned = false;
function renderResponse( id, html ){

    if ( !$warned ) {
        confirm_render = confirm( "Rendering the response will also execute" +
            " any JavaScript code that might be included in the page. " +
            "Are you sure you want to continue?" );

        $warned = confirm_render;
        if( !confirm_render){
            return;
        }

    }

    $( '#' + id ).html( $( '<iframe style="width: 100%; height: 400px" ' + 'src="' + html + '" />' ) );
}

function getElem(id) {
    return document.getElementById(id)
}

function report_fp(i) {

    if (!email_address) {
        email_address = prompt("Please enter your e-mail address:", "")
    }

    if (!email_address) return false;

    // get some values from elements on the page:
    var $form = $("#false_positive_" + i),
        issue = $form.find('input[name="issue"]').val(),
        module = $form.find('input[name="module"]').val(),
        url = $form.find('input[name="url"]').val();

    // Send the data using post and put the results in a div
    $.post("<%=REPORT_FP_URL%>", {
        email_address: email_address,
        url: url,
        module: module,
        issue: issue,
        configuration: configuration
    }, function () {
        $("#fp_report_msg").html("Done!")
    });

    $(function () {
        var fp_txt = '<p>Please wait while the data is being transferred...</p>';
        $("#fp_report_msg").html(fp_txt);

        $("#fp_report_msg").dialog({
            modal: true,
            buttons: {
                Ok: function () {
                    $(this).dialog("close");
                    $("#fp_report_msg").html(fp_txt);
                }
            }
        });
    });

}

function toggleElem(id) {

    if (getElem(id).style.display == 'none' || getElem(id).style.display == '') {
        getElem(id).style.display = 'block';
        sign = '[-]';
    } else {
        getElem(id).style.display = 'none';
        sign = '[+]';
    }

    if (getElem(id + '_sign')) {
        getElem(id + '_sign').innerHTML = sign;
    }
}


function inspect(id) {
    $(id).dialog({
        height: 500,
        width: 1000,
        modal: true
    });
}

function searchIssues( val ){
    $(".issue").show();

    if( val != '' ){
        $(".issue:not(:icontains(" + val +"))").hide();
    } else {
        $(".issue").show();
    }
}

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

    // initialize the function
    // as a parameter we are sending a selector. For this particular script we must select the unordered (or ordered) list item element
    tabs('nav ul');

    $("#summary-tabs").tabs();
    $("#issue-tabs").tabs();
    $("#untrusted-tabs").tabs();
    $("#plugin-tabs").tabs();
    $("#plugin-meta-tabs").tabs();
    $("#sitemap-tabs").tabs();
    $("#configuration-tabs").tabs();

    var issues;
    issues = new Highcharts.Chart({
        chart: {
            renderTo: 'chart-issues',
            defaultSeriesType: 'column',
            backgroundColor: '#ccc'
        },
        title: {
            text: 'Issues by type'
        },
        xAxis: {
            categories: <%= graph_data[:issues].keys.to_s %>
        },
        yAxis: {
            min: 0,
            title: {
                text: 'Total issues'
            },
            stackLabels: {
                enabled: true,
                style: {
                    fontWeight: 'bold',
                    color: (Highcharts.theme && Highcharts.theme.textColor) || 'gray'
                }
            }
        },
        legend: {
            align: 'right',
            x: -100,
            verticalAlign: 'top',
            y: 20,
            floating: true,
            backgroundColor: (Highcharts.theme && Highcharts.theme.legendBackgroundColorSolid) || 'white',
            borderColor: '#CCC',
            borderWidth: 1,
            shadow: true
        },
        tooltip: {
            formatter: function() {
                return '<b>'+ this.x +'</b><br/>'+
                    this.series.name +': '+ this.y +'<br/>'+
                        'Total: '+ this.point.stackTotal;
            }
        },
        plotOptions: {
            column: {
                stacking: 'normal',
                dataLabels: {
                    enabled: true,
                    color: (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'white'
                }
            }
        },
        series: [
            {
                name: 'Trusted',
                data: <%= graph_data[:trusted_issues].values.to_s %>
            },
            {
                name: 'Untrusted',
                data: <%= graph_data[:untrusted_issues].values.to_s %>
            }
        ]
    });

    var severities;
    severities = new Highcharts.Chart({
        chart: {
            renderTo: 'chart-severities',
            backgroundColor: '#ccc'
        },
        title: {
            text: 'Severity levels'
        },
        tooltip: {
            formatter: function () {
                return '<b>' + this.point.name + '</b>: ' + this.y + ' %';
            }
        },
        series: [{
            type: 'pie',
            data: [ <% graph_data[:severities].each do | severity | %> <%= severity.to_s %> , <% end %> ]
        }]
    });

    var elements;
    elements = new Highcharts.Chart({
        chart: {
            renderTo: 'chart-elements',
            backgroundColor: '#ccc'
        },
        title: {
            text: 'Issues by elements'
        },
        tooltip: {
            formatter: function () {
                return '<b>' + this.point.name + '</b>: ' + this.y + ' %';
            }
        },
        series: [{
            type: 'pie',
            data: [ <% graph_data[:elements].each do |element| %> <%= element.to_s %> , <% end %> ]
        }]
    });

    var verification;
    verification = new Highcharts.Chart({
        chart: {
            renderTo: 'chart-verification',
            backgroundColor: '#ccc'
        },
        title: {
            text: 'Requiring manual verification'
        },
        tooltip: {
            formatter: function () {
                return '<b>' + this.point.name + '</b>: ' + this.y + ' %';
            }
        },
        series: [{
            type: 'pie',
            data: [ <% graph_data[:verification].each do |severity| %> <%= severity.to_s %> , <% end %> ]
        }]
    });

    var trust;
    trust = new Highcharts.Chart({
        chart: {
            renderTo: 'chart-trust',
            backgroundColor: '#ccc'
        },
        title: {
            text: 'Result trust'
        },
        tooltip: {
            formatter: function () {
                return '<b>' + this.point.name + '</b>: ' + this.y + ' results.';
            }
        },
        series: [{
            type: 'pie',
            data: [ <% graph_data[:trust].each do |trust| %> <%= trust.to_s %> , <% end %> ]
        }]
    });

});
