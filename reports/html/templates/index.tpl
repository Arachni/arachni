<!DOCTYPE html 
     PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN"
     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" dir="ltr" lang="en-US">
    
    <!-- 
        $Id$
        HTML Report template for Arachni - Web Application Vulnerability Scanning Framework
     -->
     
    <head>
        <title>Web Application Security Report - Arachni Framework</title>
    </head>
    
    <body>
    
    <style>
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
        padding-top: 100px;
        display: block;        
    }
    
    .page_break {
        padding: 35px;
        border-bottom: 2px solid grey;
    }
    </style>
    
    
    <div id="main">
    
    <h1>Web Application Security Report - Arachni Framework</h1>
    
    <h2>Configuration</h2>
    <b>Version</b>: {{arachni.version}}<br/>
    <b>Revision</b>: {{arachni.revision}}<br/>
    <b>Audit date</b>: {{audit.date}}<br/>
    <br/>

    <h3>Runtime options</h3>
    
    <div class="left">
      <b>URL:</b> {{arachni.options.url}}<br/>
      <b>User agent:</b> {{arachni.options.user_agent | escape}}<br/>
      
      <br/>
      
      <b>Audited elements</b>
      <ul>
      
      {% if arachni.options.audit_links %}
          <li>Links</li>
      {% endif %}
      
      {% if arachni.options.audit_forms %}
          <li>Forms</li>
      {% endif %}
      
      {% if arachni.options.audit_cookies %}
          <li>Cookies</li>
      {% endif %}
      
      </ul>
      
      <div class="left">
        <h4>Modules</h4>
        <ul>
        {% for mod in arachni.options.mods %}
            <li>{{mod}}</li>
        {% endfor %} 
        </ul>
      
      
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
      
    </div>
    
      <h4>Filters</h4>
      <ul>
      
      <li>
        Exclude:
        <ul>
        {% if arachni.options.exclude != empty %}
        
          {% for exclude in arachni.options.exclude %}
              <li>{{exclude | escape}}</li>
          {% endfor %}
        {% else %}
            <li>N/A</li>
        {% endif %} 
        </ul>
        </li>
        <li>
        Include:
        <ul>
        {% if arachni.options.include != empty %}
        
          {% for include in arachni.options.include %}
              <li>{{include | escape}}</li>
          {% endfor %}
          
        {% else %}
            <li>N/A</li>
        {% endif %} 
        </ul>
        </li>
        
        <li>
        Redundant:
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
    
    <div class="vulns">
      <h2>Vulnerabilities</h2>
  
      {% for vuln in audit.vulns %}
      <div class="left">
        <b>Module name</b>: {{vuln.mod_name}}<br/>
        <b>Vulnerable variable</b>: {{vuln.var}}<br/>
        <b>Vulnerable URL</b>: {{vuln.url}}<br/>
        <b>HTML Element</b>
        <p class="note">{{vuln.elem}}</p>
         
         
        <h3>Description</h3>
        <p class="note">{{vuln.description}}</p>
        <br/>
        <b>Injected value</b>:
        <pre class="note">{{vuln.injected | escape}}</pre>
      </div>
      
      <b>CWE</b>: <a href="{{vuln.cwe_url}}">{{vuln.cwe}}</a><br/>
      <b>Severity</b>: {{vuln.severity}}<br/>
      <b>CVSSV2</b>: {{vuln.cvssv2}}
      
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
      
      <br/><br/><br/><br/><br/><br/>
      <br/><br/>
      <b>ID</b>:<br/>
      <pre class="note">{{vuln.id | escape}}</pre>
      <b>Regular expression</b>:<br/>
      <pre class="note">{{vuln.regexp | escape}}</pre>
      
      <b>Matched by the regular expression</b>:<br/>
      <pre class="note"> {{vuln.regexp_match | escape}}<br/></pre>

      <table>
      <tr>
        <th>
          <h3 style="padding-left: 400px">Headers</h3>
        </th>
      </tr>
      <tr>
      <td style="vertical-align: top">
        <h4>Request</h4>
        <pre class="note">
        {% for header in vuln.headers.request %}
            {{header | join '-' | escape}}
        {% endfor %}
        </pre>
      </td>
      
      <td>
        <h4>Response</h4>
        <pre class="note">
        {% for header in vuln.headers.response %}
            {{header | escape}}
        {% endfor %}
        </pre>
        </td>
      </tr>
      </table>
      
      {% if vuln.remedy_guidance != "" %}
        <h3> Remedial guidance</h3>
        {{vuln.remedy_guidance}}
      {% endif %}
      
      {% if vuln.remedy_code != "" %}
        <h3> Remedial code</h3>
        <pre class="code note">{{vuln.remedy_code | escape}}</pre>
      {% endif %}
      
      <br/>
      <h3>HTML Response</h3>
      <iframe style="width: 100%; height: 300px" src="data:text/html;base64,
      {{vuln.escaped_response}}"></iframe>
  
      <p class="page_break"></p>
      <br/>
      {% endfor %}
    
    </div>
    
    </body>
    
</html>
