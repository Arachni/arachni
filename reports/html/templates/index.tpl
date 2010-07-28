<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en-US" xml:lang="en-US">
<!-- 
        $Id$
        HTML Report template for Arachni - Web Application Vulnerability Scanning Framework
     -->

<head>
  <meta name="generator" content=
  "HTML Tidy for Linux/x86 (vers 11 February 2007), see www.w3.org" />

  <title>Web Application Security Report - Arachni Framework</title>
  <style type="text/css">
/*<![CDATA[*/
      body { 
        padding: 0 20px;
        font-family: "Lucida Sans", "Lucida Grande", Verdana, Arial, sans-serif; 
        font-size: 13px;
      }
      body.frames { padding: 10px; }
      h1 { font-size: 25px; margin: 1em 0 0.5em; padding-top: 4px; border-top: 1px dotted #d5d5d5; }
      h2 { 
        padding: 0;
        padding-bottom: 3px;
        border-bottom: 1px #aaa solid;
        font-size: 1.4em;
        margin: 1.8em 0 0.5em;
      }
      .note { 
        color: #222;
        -moz-border-radius: 3px; -webkit-border-radius: 3px; 
        background: #e3e4e3; border: 1px solid #d5d5d5; padding: 7px 10px;
      }
      
      p {
        padding: 0;
        margin: 0;
      }
      a:link, a:visited { text-decoration: none; color: #05a; }
      a:hover { background: #ffffa5; }
      
      #search { position: absolute; right: 14px; top: 0px; }
      #search a:link, #search a:visited { 
        display: block; float: left; margin-right: 4px;
        padding: 8px 10px; text-decoration: none; color: #05a; background: #eaeaff;
        border: 1px solid #d8d8e5;
        -moz-border-radius-bottomleft: 3px; -moz-border-radius-bottomright: 3px; 
        -webkit-border-bottom-left-radius: 3px; -webkit-border-bottom-right-radius: 3px;
      }
      #search a:hover { background: #eef; color: #06b; }
      #search a.active { 
        background: #568; padding-bottom: 20px; color: #fff; border: 1px solid #457; 
        -moz-border-radius-topleft: 5px; -moz-border-radius-topright: 5px;
        -webkit-border-top-left-radius: 5px; -webkit-border-top-right-radius: 5px;
      }
      #search a.inactive { color: #999; }

      #menu { font-size: 1.3em; color: #bbb; top: -5px; position: relative; }
      #menu .title, #menu a { font-size: 0.7em; }
      #menu .title a { font-size: 1em; }
      #menu .title { color: #555; }
      #menu a:link, #menu a:visited { color: #333; text-decoration: none; border-bottom: 1px dotted #bbd; }
      #menu a:hover { color: #05a; }
      #menu .noframes { display: none; }
      
      #footer { margin-top: 15px; border-top: 1px solid #ccc; text-align: center; padding: 7px 0; color: #999; }
      #footer a:link, #footer a:visited { color: #444; text-decoration: none; border-bottom: 1px dotted #bbd; }
      #footer a:hover { color: #05a; }
      
      #search_frame {
        background: #fff;
        display: none;
        position: absolute; 
        top: 36px; 
        right: 18px;
        width: 500px;
        height: 80%;
        overflow-y: scroll;
        border: 1px solid #999;
        border-collapse: collapse;
        -webkit-box-shadow: -7px 5px 25px #aaa;
        -moz-box-shadow: -7px 5px 25px #aaa;
        -moz-border-radius: 2px;
        -webkit-border-radius: 2px;
      }
      
     pre.code { color: #000; }
    
    .left {
        float:left;
        padding-right: 100px;
    }
    
    .vulns {
        width: 100%;
        display: block;        
    }
    
    .page_break {
        padding: 35px;
        border-bottom: 2px solid grey;
    }
    
    .variant {
        display: none;
    }
    
    .variant_header {
        padding-bottom: 3px;
        border-bottom: 1px #aaa solid;
    }
    
  /*]]>*/
  </style>
  <style type="text/css">
/*<![CDATA[*/
  iframe.c4 {width: 100%; height: 300px}
  tr.c3, td.c3 {vertical-align: top}
  td.c3 {vertical-align: top}
  h3.c2 {padding-left: 400px}
  li.c1 {list-style: none}
  /*]]>*/
  </style>
  
  <script type="text/javascript">

  function $() {
      var elements = new Array();
      for (var i = 0; i < arguments.length; i++) {
              var element = arguments[i];
              if (typeof element == 'string')
                  element = document.getElementById(element);
              if (arguments.length == 1)
                  return element;
              elements.push(element);
      }
      return elements;
  }
    
  function toggleElem( id ){

    if( $(id).style.display == 'none' || 
        $(id).style.display == '' )
    {
        $(id).style.display    = 'block';
        sign = '[-]';
    } else {
        $(id).style.display    = 'none';
        sign = '[+]';
    }
    
    if( $(id + '_sign') ){
            $(id + '_sign').innerHTML = sign;
    }
    
  }
  </script>
  
</head>

<body>
  <div id="main">
    <h1>Web Application Security Report - Arachni Framework</h1>

    <h2>Configuration</h2><strong>Version</strong>: {{arachni.version}}<br />
    <strong>Revision</strong>: {{arachni.revision}}<br />
    <strong>Audit date</strong>: {{audit.date}}<br />
    <br />

    <h3>Runtime options</h3>

      <strong>URL:</strong> {{arachni.options.url}}<br />
      <strong>User agent:</strong> {{arachni.options.user_agent | escape}}<br />
      
      <table>
        <tr>
        
        <th>
            <h4>Audited elements</h4>
        </th>
        
        <th>
            <h4>Modules</h4>
        </th>
        
        <th>
            <h4>Filters</h4>
        </th>
        
        </tr>
      <tr  class="c3">
      <td>
      <ul>
        {% if arachni.options.audit_links %}
        <li>Links</li>
        {% endif %}
        
        {% if arachni.options.audit_forms %}
        <li>Forms</li>
        {% endif %}
        
        {% if arachni.options.audit_cookies %}</li>
        <li>Cookies</li>
        {% endif %}
      </ul>
    </td>

      <td>
        <ul>
          {% for mod in arachni.options.mods %}
          <li>{{mod}}</li>
          {% endfor %}
        </ul>
      </td>
      <td>
      <ul>
        <li>Exclude:

          <ul>
            {% if arachni.options.exclude != empty %}
              {% for exclude in arachni.options.exclude %}</li>

            <li>{{exclude | escape}}</li>

              {% endfor %}
            {% else %}
            <li>N/A</li>
            {% endif %}
          </ul>
        </li>
        <li>Include:

          <ul>
            {% if arachni.options.include != empty %}
              {% for include in arachni.options.include %}</li>

            <li>{{include | escape}}</li>

              {% endfor %}
            {% else %}
            <li>N/A</li>
            {% endif %}
          </ul>
        </li>
        <li>Redundant:

          <ul>
            {% if arachni.options.redundant != empty %}
              {% for redundant in arachni.options.redundant %}

            <li>{{redundant.regexp | escape}} - Count {{redundant.count}}</li>

              {% endfor %}
            {% else %}
            <li>N/A</li>
            {% endif %}
          </ul>
        </li>
      </ul>

      </td>
      
      </tr>
      
      <tr>
      <td>
        <h4>Cookies</h4>

        <ul>
          {% if arachni.options.cookies != empty and arachni.options.cookies != null %}
            {% for cookie in arachni.options.cookies %}
          <li>{{cookie.name}}: {{cookie.value | escape}}</li>
            {% endfor %}
          {% else %}
          <li>N/A</li>
          {% endif %}
        </ul>
        </td>
        </tr>
      </table>

      <div class="vulns">
        <h2>Vulnerabilities</h2>
        
        {% for vuln in audit.vulns %}

        <h3>{{vuln.name}}</h3>
        <div class="left">
          <strong>Module name</strong>: {{vuln.mod_name}}<br />
          <strong>Vulnerable variable</strong>: {{vuln.var}}<br />
          <strong>Vulnerable URL</strong>: {{vuln.url}}<br />
          <strong>HTML Element</strong>

          <p class="note">{{vuln.elem}}</p>

          <h3>Description</h3>
          <p class="note">{{vuln.description}}</p>
        
          {% if vuln.remedy_guidance != "" %}
          <h3>Remedial guidance</h3>
          <p class="note">{{vuln.remedy_guidance}}</p>
          {% endif %}
          
          {% if vuln.remedy_code != "" %}
          <h3>Remedial code</h3>
          <pre class="code note">{{vuln.remedy_code | escape}}</pre>
          {% endif %}
            
        </div>
        
        <strong>CWE</strong>: <a href="{{vuln.cwe_url}}">{{vuln.cwe}}</a><br />
        <strong>Severity</strong>: {{vuln.severity}}<br />
        <strong>CVSSV2</strong>: {{vuln.cvssv2}}

        <h3>References</h3>

        <ul>
          {% if vuln.references != empty %}
            {% for ref in vuln.references %}

          <li>{{ref.name}} - <a href="{{ref.value}}">{{ref.value}}</a></li>

            {% endfor %}
          {% else %}
          <li>N/A</li>
          {% endif %}
        </ul>
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        <br />
        
        {% assign toploop_index = forloop.index %}
        {% for variant in vuln.variations %}
        <h3 class="variant_header">
          <a href='javascript:toggleElem( "var_{{toploop_index}}_{{forloop.index}}" )'>
            <span id="var_{{toploop_index}}_{{forloop.index}}_sign">[+]</span>
            Variant {{forloop.index}}
          </a>
        </h3>
        
        <strong>Vulnerable URL</strong>: {{variant.url}}<br />
        
        <div class="variant" id="var_{{toploop_index}}_{{forloop.index}}">
        <strong>Injected value</strong>:
        <pre class="note">{{variant.injected | escape}}</pre>
        
        <strong>ID</strong>:<br />
        <pre class="note">{{variant.id | escape}}</pre>
        
        <strong>Regular expression</strong>:<br />
        <pre class="note">{{variant.regexp | escape}}</pre>
        
        <strong>Matched by the regular expression</strong>:<br />
        <pre class="note">{{variant.regexp_match | escape}}</pre>

        <table>
          <tr>
            <th>
              <h3 class="c2">Headers</h3>
            </th>
          </tr>

          <tr>
            <td class="c3">
              <h4>Request</h4>
              <pre class="note">{% for header in variant.headers.request %}
{{header | join '-' | escape}}{% endfor %}</pre>
            </td>

            <td>
              <h4>Response</h4>
              <pre class="note">{% for header in variant.headers.response %}
{{header | escape}}{% endfor %}</pre>
            </td>
          </tr>
          
        </table>
        
        <br/>

        <h3>HTML Response</h3><iframe class="c4" src=
        "data:text/html;base64, {{variant.escaped_response}}"></iframe>
        
        </div>
        {% endfor %}

        <p class="page_break"></p><br />
        {% endfor %}
      </div>
  </div>
</body>
</html>
