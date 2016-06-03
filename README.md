# blaze-extreme-container-manager

LUA code for Garry's mod so you can realy _manage_ your Mesos platform with style!

More info can be found here:

https://www.wehkamplabs.com/blog/2016/06/02/docker-and-zombies/

### Getting started
Assuming we're going to run locally, you'll need to copy both files to the general lua folder. Here's how that looks like on MacOS:

```
/Users/harm/Library/Application Support/Steam/steamapps/common/GarrysMod/garrysmod/lua/
```

Now launch Garry's mod, start a new single or multiplayer game and make sure you can access the game console.
When done loading the map, open your console and paste the following to load the gui bits:

```
lua_openscript_cl gui.lua
```

And this is required for the server part, which will connect the game with Mesos. Remember, after loading this everything will start moving - so watch out ;)

```
lua_openscript chaos.lua
```
