Mapper
======

<h3>Code Climate</h3>
<a href="https://codeclimate.com/repos/5313ca5ce30ba0768e0000eb/feed">
    <img src="https://codeclimate.com/repos/5313ca5ce30ba0768e0000eb/badges/ced2362d8e47d6a3c8e7/gpa.png" />
</a>

<h2>Step by step configuration</h2>
<ol>
  <li><code>bundle install</code> - install all dependencies for Mapper's work</li>
  <li>Add shop database and other configuration in <b>config/config.yaml</b></li>
  <li><code>rake setup_storage</code> - setup storage database</li>
  <li>Add shop database connection and fields information for search server in <b>solr/solr/conf/data-config.xml and schema.xml</b></li>
  <li><code>rake start_solr</code> - start search server</li>
  <li><code>rake start_webserver</code> - start web server</li>
  <li><code>rake spec</code> - test all components</li>
</ol>

<h2>Components</h2>

<h3>AMQP broker</h3>
<p>In order to send commands to Mapper you have to install and configure rabbitmq-server. 
After installation you have to start it with command 
<code>sudo service rabbitmq-server start</code>  </p>
<p>Command <code>rake spec[amqp]</code> for testing AMQP server</p>

<h3>Search server</h3>
<p>Mapper uses Solr for searching products and comparing their articles</p>
<p>Before Mapper runs, you have to start search server, using command <code>rake start_solr</code></p>
<p>Go to <a href="http://localhost:8983/solr" target="_blank">http://localhost:8983/solr</a> if you want to see Solr admin and test some search queries</p>
<p>Command <code>rake spec[solr]</code> for testing search server</p>

<h3>Web server</h3>
<p>Result of Mapper's work you can see in web browser. <a href="http://localhost:4567" target="_blank">http://localhost:4567</a></p>
<p>Command <code>rake spec[webserver]</code> for testing web server</p>

<h3>Storage Database</h3>
<p>Mapper process price-lists and save results to storage database. </p>
<p>Also after comparing articles from price-lists to articles from shop database, results of these comparisons save in storage database too</p>
<p>command <code>rake setup_storage</code> will install storage database and will create structure</p>

<h2>Rake commands</h2>
    <ul>
        <li><b>rake spec</b> # &lt;= starts RSpec tests</li>
        <li><b>rake start_solr</b> # &lt;= starts Solr</li>
        <li><b>rake stop_solr</b> # &lt;= stops Solr</li>
        <li><b>rake run</b> # &lt;= runs Mapper</li>
</ul>
<h2>Continuous Integration</h2>
    <h3>TeamCity</h3>
    <ul>
        <li>home : /home/nychos/TeamCity</li>
        <li>port: 8111</li>
        <li>address: <b><a href="88.198.94.236:8111" target="_blank">88.198.94.236:8111</a></b></li>
        <li>login: admin</li>
        <li>password: uteam</li>
   </ul>
