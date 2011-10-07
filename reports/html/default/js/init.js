    <%= erb 'js/jquery.min.js' %>
    <%= erb 'js/jquery-ui.min.js' %>
    <%= erb 'js/highcharts.js' %>


      var configuration = <%=js_multiline( conf )%>
      var email_address;

      function getElem( id ){
          return document.getElementById(id)
      }

      function report_fp( i ) {

          if( !email_address ) {
              email_address = prompt( "Please enter your e-mail address:", "")
          }

          if( !email_address )
              return false;

          // get some values from elements on the page:
          var $form = $( "#false_positive_" + i ),
              issue = $form.find( 'input[name="issue"]' ).val(),
              module = $form.find( 'input[name="module"]' ).val(),
              url = $form.find( 'input[name="url"]' ).val();

          // Send the data using post and put the results in a div
         $.post( "<%=REPORT_FP_URL%>",
              { email_address: email_address, url: url, module: module, issue: issue, configuration: configuration } ,
              function( ) {
                  $( "#fp_report_msg" ).html( "Done!" )
              }
          );

          $(function() {
                var fp_txt = '<p>Please wait while the data is being transferred...</p>';
                $( "#fp_report_msg" ).html( fp_txt );

                $( "#fp_report_msg" ).dialog({
                modal: true,
                buttons: {
                    Ok: function() {
                        $( this ).dialog( "close" );
                        $( "#fp_report_msg" ).html( fp_txt );
                    }
                }
              });
          });

      }

      function toggleElem( id ){

            if( getElem(id).style.display == 'none' ||
                getElem(id).style.display == '' )
            {
                getElem(id).style.display    = 'block';
                sign = '[-]';
            } else {
                getElem(id).style.display    = 'none';
                sign = '[+]';
            }

            if( getElem(id + '_sign') ){
                getElem(id + '_sign').innerHTML = sign;
            }
      }


      function inspect( id ){
          $( id ).dialog({
              height: 500,
              width: 1000,
              modal: true
          });
      }

      jQuery(function($){

        tabs = function(options) {

            var defaults = {
                selector: '.tabs',
                selectedClass: 'selected'
            };

            if(typeof options == 'string') defaults.selector = options;
            var options = $.extend(defaults, options);

            return $(options.selector).each(function(){

                var obj = this;
                var targets = Array();

                function show(i){
                    $.each(targets,function(index,value){
                        $(value).hide();
                    })
                    $(targets[i]).fadeIn('fast');
                    $(obj).children().removeClass(options.selectedClass);
                    selected = $(obj).children().get(i);
                    $(selected).addClass(options.selectedClass);
                };

                $('a',this).each(function(i){
                    targets.push($(this).attr('href'));
                    $(this).click(function(e){
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

        $( "#summary-tabs" ).tabs();
        $( "#issue-tabs" ).tabs();
        $( "#untrusted-tabs" ).tabs();
        $( "#plugin-tabs" ).tabs();
        $( "#plugin-meta-tabs" ).tabs();

      });


        var issues; // globally available
        $(document).ready(function() {
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
                        categories: <%=graph_data[:issues].keys.to_s %>
                },
                yAxis: {
                    title: {
                        text: ''
                    }
                },
                series: [{
                    data: <%=graph_data[:issues].values.to_s %>
                     }]
                });
           });

            var severities;
            $(document).ready(function() {
               severities = new Highcharts.Chart({
                  chart: {
                     renderTo: 'chart-severities',
                     backgroundColor: '#ccc'
                  },
                  title: {
                     text: 'Severity levels'
                  },
                  tooltip: {
                     formatter: function() {
                        return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
                 }
              },
               series: [{
                 type: 'pie',
                 data: [
                    <% graph_data[:severities].each do |severity| %>
                    <%=severity.to_s%>,
                    <%end%>
                 ]
              }]
           });
        });

        var elements;
        $(document).ready(function() {
           elements = new Highcharts.Chart({
              chart: {
                 renderTo: 'chart-elements',
                 backgroundColor: '#ccc'
              },
              title: {
                 text: 'Issues by elements'
              },
              tooltip: {
                 formatter: function() {
                    return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
                 }
              },
               series: [{
                 type: 'pie',
                 data: [
                    <% graph_data[:elements].each do |severity| %>
                    <%=severity.to_s%>,
                    <%end%>
                 ]
              }]
           });
        });

        var verification;
        $(document).ready(function() {
           verification = new Highcharts.Chart({
              chart: {
                 renderTo: 'chart-verification',
                 backgroundColor: '#ccc'
              },
              title: {
                 text: 'Requiring verification'
              },
              tooltip: {
                 formatter: function() {
                    return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
                 }
              },
               series: [{
                 type: 'pie',
                 data: [
                    <% graph_data[:verification].each do |severity| %>
                    <%=severity.to_s%>,
                    <%end%>
                 ]
              }]
           });
        });
