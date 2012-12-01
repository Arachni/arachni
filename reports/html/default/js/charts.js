
function pie( holder, title, data, colors ) {

    container = $( '#' + holder );
    container.empty();

    $.jqplot( holder,
        [ data ],
        {
            seriesColors: colors,
            title: title,
            seriesDefaults: {
                renderer: $.jqplot.PieRenderer,
                rendererOptions: {
                  showDataLabels: true
                }
            },
            legend: {
                show: true
            },
            grid: {
                drawBorder: false,
                drawGridlines: false,
                background: '#cccccc',
                shadow: false
            }
        }
    );
}


function drawBars(){
    <% trusted   = graph_data[:trusted_issues].values %>
    <% untrusted = graph_data[:untrusted_issues].values %>

    $('#chart-issues').empty();
    $('#chart-issues').attr( "width",( $('#canvas-container').width() ) );
    $('#chart-issues').attr( "height",( $('#canvas-container').height() ) );


    $.jqplot( 'chart-issues',
    [
    <%= graph_data[:trusted_issues].values.to_json %>,
    <%= graph_data[:untrusted_issues].values.to_json %>
    ],
    {
        seriesColors: [ "#4572A7", "#AA4643" ],
        title: 'Issues by type',
        highlighter: {
            lineWidthAdjust: 2.5,
            sizeAdjust: 5,
            showTooltip: true,
            tooltipLocation: 'nw',
            fadeTooltip: true,
            tooltipFadeSpeed: "fast",
            tooltipOffset: 2,
            tooltipAxes: 'both',
            tooltipSeparator: ', ',
            useAxesFormatters: true,
            tooltipFormatString: '%.5P'
        },
        stackSeries: true,
        seriesDefaults:{
            renderer:$.jqplot.BarRenderer,
            rendererOptions: {
                barPadding: 50,
                barDirection: 'vertical',
                barWidth: null,
                highlightMouseMove: true,
                smooth: true,
                animation: {
                    show: true
                }
            },
            pointLabels: {show: true}
        },
        legend: {
            show: true,
        },
        axesDefaults: {
            rendererOptions: {
                drawBaseline: false
            }
        },
        axes: {
            xaxis: {
                renderer: $.jqplot.CategoryAxisRenderer,
                ticks: <%= graph_data[:trusted_issues].keys.map { |k| k.gsub( ' ', "\n" ) }.to_json %>,
                drawMajorGridlines: false,
                tickOptions: {
                    mark: 'outside',
                    showMark: true,
                    showGridline: true,
                    markSize: 4,
                    show: true,
                    showLabel: true,
                    formatString: '',
                }
            }
        },
        grid: {
            background: '#cccccc',
            gridLineColor: '#c0c0c0',
            shadow: true,
            shadowAngle: 45,
            shadowOffset: 1.5,
            shadowWidth: 3,
            shadowDepth: 3,
            shadowAlpha: 0.07,
            drawBorder: false
        },
        series: [
            {
                label: 'Trusted'
            },
            {
                label: 'Untrusted'
            }
        ],
    });
}

function drawPies(){
    pie( "chart-severities", "Severity levels",
        <%= graph_data[:severities].map { |k, v| [k, v] }.to_json %>,
        [ '#BD2C00', '#DB843D', '#EDDF3C', '#89A54E' ]
    );

    pie( "chart-elements", "Issues by element",
        <%= graph_data[:elements].map { |k, v| [k.capitalize, v] }.to_json %>
    );

    pie( "chart-trust", "Result trust",
        <%= graph_data[:trust].map { |k, v| [k, v] }.to_json %>,
        [ "#4572A7", "#AA4643" ]
    );

}

<% if auditstore.issues.any? %>
drawBars();
drawPies();
$(window).resize(function() {
    drawBars( );
    drawPies();
});
<% end %>
