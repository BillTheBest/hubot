Bunch of scripts I use for my implementation of Hubot (called Jarvis).
<ul>
<li><b>jarvis</b> - hubot init script using forever (https://github.com/nodejitsu/forever) to make sure the process restarts if it dies</li>
<li><b>openhab.coffee</b> - plugin for interacting with OpenHAB (http://openhab.org) installation . This is what it can do currently:
<ul>
<li>
<code>hubot what is (openhab value)</code><br>Returns the value of (openhab value)
</li>
<li>
<code>hubot automation values matching (partial match)</code><br>Returns all the possible query options from the REST query matching (partial match), leave out the "matching..." part to return everything
</li>
<li>
<code>hubot graph me (openhab value) for (period)</code><br>Graphs the value of (openhab value) for (period). Period must be one of h,4h,8h,12h,D,3D,W,2W,M,2M,4M or Y
</li>
<li>
<code>hubot set value of (openhab value) to (value)</code><br>Sets the value of (openhab value) to (value)
</li>
<li>
<code>hubot when I say (x) I mean (y)</code><br>Allows for basic aliasing. For example:<br>
<code>hubot when I say the greenhouse temperature I mean GreenhouseTemperature</code>
<br>
will make 
<br>
<code>hubot what is GreenhouseTemperature</code>
<br>
or
<br>
<code>hubot what is the greenhouse temperature</code>
<br>
valid
</li>
<li>
The following environment variables need to be set:<br>
<code>HUBOT_OPENHAB_INTERNAL_URL - the internal URL to use for openhab</code><br>
<code>HUBOT_OPENHAB_EXTERNAL_URL - the external URL to use for openhab</code><br>
<code>OPENHAB_USER - the auth user to use to access openhab</code><br>
<code>OPENHAB_PASSWORD - the auth user's password to use to access openhab</code><br>
</li>
</ul>
<li><b>rick.coffee</b> - Some general debugging stuff
</ul>
