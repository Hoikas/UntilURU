# Untìl URU
## Background Information
Untìl URU, released in August 2004, was a stop-gap way to play URU Live after its first cancellation
in February 2004. Untìl URU represented the state of the online URU Live game at the time of its closure.
When Cyan reopened their doors in late 2005, they began work on what would eventually become
Myst Online: URU Live. Many players are only familiar with the later incarnation of the game. The
goal of this project is to allow spinning up a legacy URU server so players can experience URU as
it was from 2004 to 2006.

The servers were originally designed to run on Red Hat Linux 9 or FreeBSD 4 with MySQL 4.0. The Plasma
Server software does not function on a wide range of operating systems due to the advancement of
technology. Therefore, this project will enable you to deploy a known working configuration of Plasma
Servers in docker in a custom Debian Sarge container.

## Security Disclaimer
The Untìl URU software is from August 2004, therefore, it is known to use libraries and cryptographic
techniques that are known to be questionable at best and broken in the worst case. Do not use this
platform to store any data that you do not wish to have disclosed to the entire world. Specifically,
do **NOT** share your Untìl URU account password with any other account; the password hashing mechanism
is known to be defective.

## Licensing
Plasma Servers, URU, URU client patches, and Vault Manager are property of Cyan Worlds, Inc.
All shell scripts, dockerfiles, and infrastructure to support the deployment of Plasma Servers
into containers is licensed under the GNU GPLv3. See LICENSE.txt for more information.

# Running
## Getting Started
Before we begin, be sure to install [Docker](https://www.docker.com/) and Docker Compose. Docker
desktop on Windows will work just fine. Be sure to use the WSL2 backend for best performance. Then,
checkout this repository on your computer either by downloading it from GitHub or by cloning it
with git.

## Setting Up the Server
Setting up the server should be straightforward because docker will do all of the heavy-lifting
for you. Open the terminal of your choice and change to the directory containing the content
of this repository. Then execute `docker-compose up`. This should cause the server containers to
build and start.

**NOTE**: If the container *untiluru_agent_1* fails to start and you are on Windows, this might be
due to a conflict between the URU servers and the *Windows Media Player Network Sharing Service*. You
can fix this by running `Services.msc` from the start menu and manually stopping the *Windows Media*
*Player Network Sharing Service*.

Once the servers are running, you should see lines like the following being printed to the console:
```
vault_1   | DBG:  Timed: 0.000362 secs: IdleTime DbCleanup
vault_1   | DBG:  Timed: 0.000374 secs: IdleTime DbCleanup
vault_1   | DBG:  Timed: 0.000319 secs: IdleTime DbCleanup
```

If you are seeing messages fly by at extreme speed that talk about need[ing] agent, auth, lookup, or
vault, then something has gone wrong. Try bringing the servers down by pressing Ctrl+C and re-running
`docker-compose up`. If this does not fix the problem, please open an issue.

Once you are ready to shut down your server, you can do so by pressing Ctrl+C. If you would like to
run it in the background without a terminal open, use the command `docker-compose up -d` to start
the server and the command `docker-compose down` to shut it down.

**NOTE**: At this time, please note that using this project for multiplayer or even connecting
from a different computer than the one hosting the containers is ill-supported at this time.

## Setting Up the Client
Untìl URU required retail copies of *URU: Complete Chronicles* or *URU: Ages Beyond Myst*. This project
retains that requirement. Please note that *Myst Online: Uru Live* will not work. Make a *copy* of
your URU install into a new directory. Now, Look in the `plasma/patches` directory of this repository.
Execute the appropriate patch for your game.

Because this was an online game, the launcher tries to update itself when you start the game.
Unfortunately, the original UU data servers are long gone. To facillitate your gameplay, I have set
up an analgous data server that matches the state of the game when it was closed down. To use it,
copy the file `client/serverconfig.ini` into your game directory. This may result in some files being
updated when you launch the game.

To improve the UX and security (somewhat), rename UruSetup.exe to UruStart.exe. This will prevent UAC
from prompting you for administrator credentials every time you start the game. It will also prevent
the known-insecure code in UruExplorer.exe from gaining potentially dangerous permissions.

Now, execute UruStart.exe. When the launcher starts, the server *Local Docker Shard* should be
selected for you. As a basic test, you can click on the *Ping Server* tab and ping the server. It
should respond in a few tens of milliseconds to a handful of pings.

## Creating Your Account
**WARNING**: The way that Untìl URU stored account information is known to be insecure. Do not use
any password that you need to keep secret.

To manage accounts on your shard, a convenience script is included with the database container
called `manage_uu`. To use this script, you will need to invoke it inside of the database container.
To do so, you will need to use the command `docker execute untiluru_db_1 manage_uu`. Without any
arguments, a simple list of help will be printed to the console.

To add an account, use `manage_uu addacct [username] [password]`. If you would like to use the
Vault Manager tool from plasma/tools, then you will need to mark your account as an administrator
by using the `manage_uu makeadmin [username]` command.

**NOTE**: The Vault Manager will always login as the first avatar on your account. There is no
limit to how many avatars are online simultaneously on a single account; however, an avatar may only
be active in one client or Vault Manager at a time.

## Congratulations!
Your Untìl URU server should now be ready for you to tinker with!
