--assigning variables for the top & bottom consoles
bconsole = Console.new(BOTTOM_SCREEN)
tconsole = Console.new(TOP_SCREEN)
--setting menu to negative before configuration file is setup
menu = -1
--controldelay makes it so you won't zoom through the menus
controldelay = 0
--I honestly have no idea what this does
configtimer = 0
--setting all these values to empty in preparation for when they will be used
uploadcoursefile = nil
uploadcoursename = nil
uploadcoursepath = nil
named = nil
pathed = nil
downloadcoursename = nil
downloadcoursepath = nil
--shortcut to where the idlist should be located
idlistpath = "/SMMOCM/idlist.txt"
--Initializing the socket system
Socket.init()
--Colors!!!!
yellow = Color.new(255, 255, 50)
red = Color.new(255, 0, 0)
green = Color.new(0, 255, 0)
blue = Color.new(0, 0, 255)
black = Color.new(0, 0, 0)
white = Color.new(255, 255, 255)
--Start the Graphics (engine?)
Graphics.init()
--Getting the directory the app is located in
appdir = System.currentDirectory()
--Always keep the top screens in memory since there aren't that many of them
topmainimg = Graphics.loadImage(appdir .. "assets/topmain.png")
topuploadimg = Graphics.loadImage(appdir .. "assets/topupload.png")
topbrowseimg = Graphics.loadImage(appdir .. "assets/topbrowse.png")
topdownloadimg = Graphics.loadImage(appdir .. "assets/topdownload.png")
topkeyinputimg = Graphics.loadImage(appdir .. "assets/keyinput.png")
fileselecttopimg = Graphics.loadImage(appdir .. "assets/fileselecttop.png")

--Create a conditions table to check against for special UI elements that have two states
conditions = {}

--import the json module
local json = require("imports/json")

--load all then json data for the gui menus
menujson = io.open(appdir .. "json/menus.json", FREAD)
menus = json:decode(io.read(menujson, 0, io.size(menujson)))
io.close(menujson)

--Create a list of UI elements
uilist = {}

--Draws the universal background for the program
function drawtopbg()
	Graphics.fillRect(0, 400, 0, 240, yellow)
end
function drawbotbg()
	Graphics.fillRect(0, 320, 0, 240, yellow)
end

function drawtop()
	if menu == -3 then
		Graphics.drawImage(0, 0, topkeyinputimg)
	end
	if menu == -2 then
		Graphics.drawImage(0, 0, fileselecttopimg)
	end
	if menu == 0 then
		Graphics.drawImage(0, 0, topmainimg)
	end
	if menu >= 1 and menu <= 5 then
		Graphics.drawImage(0, 0, topuploadimg)
	end
	if menu >= 6 and menu <= 10 then
		Graphics.drawImage(0, 0, topbrowseimg)
	end
	if menu >= 11 and menu <= 16 then
		Graphics.drawImage(0, 0, topdownloadimg)
	end
end

--Shortcut for when images need to be loaded into memory temporarily
function tempload(path)
	return Graphics.loadImage(appdir .. path)
end
--Shortcut to free just one image from memory instead of all of them
function free(img2free)
	Graphics.freeImage(img2free)
end

--Loads all necessary images for the current menu into memory
function loadmenu()
	--Get all the elements for the current menu, if there are any
	if menus[tostring(menu)] ~= nil then
		for k, v in pairs(menus[tostring(menu)]) do
			uilist[k] = Graphics.loadImage(appdir .. menus[tostring(menu)][k]["path"])
		end
	end
end
--Draws images loaded into memory onto screen, if there are any to be drawn
function drawmenu()
	if uilist ~= nil then
		for k, v in pairs(uilist) do
			if menus[tostring(menu)][k]["conditions"] ~= nil then
				requirements = menus[tostring(menu)][k]["conditions"]
				reqnum = #requirements
				reqavail = 0
				for _, x in pairs(requirements) do
					for _, c in pairs(conditions) do
						if x == c then
							reqavail = reqavail + 1
						end
					end
				end
				if reqavail == reqnum then
					xlocation = menus[tostring(menu)][k]["x"]
					ylocation = menus[tostring(menu)][k]["y"]
					altimg = tempload(menus[tostring(menu)][k]["altpath"])
					Graphics.drawImage(xlocation, ylocation, altimg)
					free(altimg)
				else
					xlocation = menus[tostring(menu)][k]["x"]
					ylocation = menus[tostring(menu)][k]["y"]
					Graphics.drawImage(xlocation, ylocation, uilist[k])
				end
			else
				xlocation = menus[tostring(menu)][k]["x"]
				ylocation = menus[tostring(menu)][k]["y"]
				Graphics.drawImage(xlocation, ylocation, uilist[k])
			end
		end
	end
end
--Frees all images from memory
function freemenu()
	if uilist ~= nil then
		for k, v in pairs(uilist) do
			Graphics.freeImage(uilist[k])
			uilist[k] = nil
		end
	end
	collectgarbage()
end

--It's just easier to have one function
--laf means "Load And Free"
function laf()
	freemenu()
	loadmenu()
end

--All the routine things to do are outside the loop so the can be called easily from inside menus
function pre_update()
	--Gotta keep those screens fresh!
	Screen.refresh()

	--Reading user input
	input = Controls.read()

	--Top screen graphics
	Graphics.initBlend(TOP_SCREEN)
	drawtopbg()
	drawtop()
	Graphics.termBlend()
	--Bottom screen graphics (these are loaded from the json)
	Graphics.initBlend(BOTTOM_SCREEN)
	drawbotbg()
	drawmenu()
	Graphics.termBlend()
end
function post_update()
	--flushing all changes to the screen
	Screen.flip()

	--decreasing the controldelay so you can input stuff again
	if controldelay > 0 then
		controldelay = controldelay - 1
	end

	--Waiting until the screen is ready
	Screen.waitVblankStart()
end
--I'm a horrible person
function update()
	pre_update()
	post_update()
end

--function that updates the console (top or bottom) in one line rather than 8
function update_console(message, console)
	Screen.waitVblankStart()
	Screen.refresh()
	Screen.clear(BOTTOM_SCREEN)
	Screen.clear(TOP_SCREEN)
	if message then
		update_console(console, message)
	else
		update_console(console, "nil")
	end
	Console.show(tconsole)
	Console.show(bconsole)
	Screen.flip()
end

--Gets keyboard input from the user
function keyInput(message)
	oldmenu = menu
	menu = -3
	laf()
	Keyboard.clear()
	Keyboard.show()
	while Keyboard.getState() ~= 1 do
		pre_update()
		Keyboard.show()
		if message ~= nil then
			Screen.debugPrint(80, 50, message, black, TOP_SCREEN)
		end
		Screen.debugPrint(90, 110, Keyboard.getInput(), black, TOP_SCREEN)
		post_update()
	end
	inputresult = Keyboard.getInput()
	menu = oldmenu
	return inputresult
end

-- this function is code "borrowed" from stackoverflow cuz i'm lazy :P
function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--Creating a dictionary for all of the numbers and the hex values that represent them
hexdict = {[0]='0', [1]='1', [2]='2', [3]='3', [4]='4', [5]='5', [6]='6', [7]='7', [8]='8', [9]='9', [10]='A', [11]='B', [12]='C', [13]='D', [14]='E', [15]='F'}

--Pretty obvious what this does, it converts all characters of a string to their hex values
--the downfall is it also doubles the size
function string.tohex(str)
    return (str:gsub('.', function (c)
		m = string.byte(c) // 16
		t = 16 * m
		r = string.byte(c) - t
        return string.format(hexdict[m] .. hexdict[r])
    end))
end

-- this is from https://gist.github.com/yi/01e3ab762838d567e65d
-- no idea why I didn't do it myself
function string.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

--selecting a file from the sd card or extdata
--if you set extdata to nil it will pull from sd card,
--otherwise it will pull from extdata
--it also simultaneously displays the "toptext" variable
--on the top screen
function file_select(extdata, toptext)
	oldmenu = menu
	menu = -2
	laf()
	selecting = true
	fileselectnum = 1
	if extdata then
		files = System.listExtdataDir("/", 6660)
	end
	if not extdata then
		files = System.listDirectory("/SMMOCM/")
	end
	fileslen = tablelength(files)
	while selecting do
		pre_update()

		curfile = files[fileselectnum]

		Screen.debugPrint(75, 110, curfile.name, black, BOTTOM_SCREEN)
		Screen.debugPrint(90, 100, toptext, black, TOP_SCREEN)

		input = Controls.read()
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			selecting = false
			controldelay = 15
			if extdata then
				resultfile = "/" .. curfile.name
			end
			if not extdata then
				resultfile = "/SMMOCM/" .. curfile.name
			end
		end

		if (Controls.check(input,KEY_DUP)) and controldelay == 0 and fileselectnum < fileslen then
			fileselectnum = fileselectnum + 1
			controldelay = 15
		end

		if (Controls.check(input,KEY_DDOWN)) and controldelay == 0 and fileselectnum > 1 then
			fileselectnum = fileselectnum - 1
			controldelay = 15
		end

		if (Controls.check(input,KEY_DDOWN)) and controldelay == 0 and fileselectnum == 1 then
			fileselectnum = fileslen
			controldelay = 15
		end

		if (Controls.check(input,KEY_DUP)) and controldelay == 0 and fileselectnum == fileslen then
			fileselectnum = 1
			controldelay = 15
		end

		post_update()
	end
	menu = oldmenu
	laf()
	return resultfile
end

--Checking for config file, this is what happens if it exists
if System.doesFileExist("/SMMOCM/config.txt") then
	configfile = io.open("/SMMOCM/config.txt", FREAD)
	--get the server ip from the config file
	configipread = io.read(configfile, 8, io.size(configfile))
	configsize = io.size(configfile)
	io.close(configfile)
	--this one line took me 3.5 hours, don't ask.
	configip = string.sub(configipread, 0, configsize - 8)
	--getting ready for main menu
	menu = 0
	loadmenu()
end

--Checking for config file, this is what happens if it doesn't exist
if System.doesFileExist("/SMMOCM/config.txt") == false then
	--getting a course file so we can extract the LockoutID
	lockidfile = io.open("/course000", FREAD, 6660)
	--creating the config file
	configfile = io.open("/SMMOCM/config.txt", FCREATE)
	--I know I could have used 2 variables, but I used one for some reason
	lockidcharnum = 16
	--iterating over 0x10 to 0x17 to get the LockoutID, and writing it to the config file
	while lockidcharnum < 24 do
		io.write(configfile, lockidcharnum-16, io.read(lockidfile, lockidcharnum, 1), 1)
		lockidcharnum = lockidcharnum + 1
	end
	--clearing the consoles for server ip entry
	--getting the server ip from the user
	configip = keyInput("Enter your server ip")
	--writing the ip the config file
	io.write(configfile, 8, configip, #configip + 8)
	--clean up
	io.close(lockidfile)
	io.close(configfile)
	--getting ready for main menu
	menu = 0
	loadmenu()
end

--function name. takes a string and makes it into a table(array, whatever. get your data structures together lua.)
--if hex is not nil then convert it the string into hex as well as making it into a table
function stringtotable(input, hex)
	local output = {}
	local splitticker = 1
	while splitticker <= string.len(input) do
		if hex then
			table.insert(output, string.sub(input, splitticker, splitticker):tohex())
		else
			table.insert(output, string.sub(input, splitticker, splitticker))
		end
		splitticker = splitticker + 1
	end
	return output
end

--iterates through "intable" looking for "value" in either the key or value.if "returnindex" is not nil,
--then return the index of where it was found as well
function checkforval(intable, value, returnindex)
	contains = false
	for k,v in pairs(intable) do
		if v == value then
			contains = true
			if returnindex then
				foundindex = k
			end
			break
		end
		if k == value then
			contains = true
			if returnindex then
				foundindex = v
			end
			break
		end
	end
	if returnindex then
		return contains, foundindex
	else
		return contains
	end
end

--Sends a POST request. GET has a limit on data so POST is better.
--I guess this could have been one line?
function post(path, data)
	--Creating socket
	socket_client_id = nil
	while socket_client_id == nil do
		socket_client_id = Socket.connect(configip, 80)
	end
	--POST
	Socket.send(socket_client_id, "POST /" .. path .. " HTTP/1.0\r\n")
	Socket.send(socket_client_id, "Content-Length: " .. #data .. "\r\n")
	Socket.send(socket_client_id, "Content-Type: application/x-www-form-urlencoded; charset=utf-8\r\n")
	Socket.send(socket_client_id, "\r\n")
	Socket.send(socket_client_id, data)
	--Closing socket
	Socket.close(socket_client_id)
end

--stole this bit from luausers, you can google it

function range(a, b, step)
  if not b then
    b = a
    a = 1
  end
  step = step or 1
  local f =
    step > 0 and
      function(_, lastvalue)
        local nextvalue = lastvalue + step
        if nextvalue <= b then return nextvalue end
      end or
    step < 0 and
      function(_, lastvalue)
        local nextvalue = lastvalue + step
        if nextvalue >= b then return nextvalue end
      end or
      function(_, lastvalue) return lastvalue end
  return f, nil, a - step
end

--There was an original plan to compress the data before sending
--It failed.  If you want to get this to work, it's on Rosettacode,
--but I couldn't get their version to work properly so I had to rewrite-ish it
--I probably made a stupid mistake somewhere and it will work easily if someone
--else tries to implement it

function compress(input)
	compoutput = {}
	local dict = {}
	dict_size = 255
	for k in range(0, dict_size) do
		dict[string.char(k)] = k
	end
	local w = ""
	first = true
	for c in input:gmatch"." do
		if first then
			wc = "" .. c
			first = nil
		else
			wc = w .. c
		end
		if dict[wc] then
            w = wc
        else
            table.insert(compoutput, dict[w])
            dict[wc] = dict_size
            dict_size = dict_size + 1
            w = c
		end
	end

	if w then
		table.insert(compoutput, dict[w])
	end

	return compoutput
end

function launchgame()
	cartid = System.getGWRomID()
	cartid = string.sub(cartid, #cartid - 3, #cartid)
	if cartid == "AJHJ" or cartid == "AJHE" or cartid == "AJHP" then
		System.launchGamecard()
	end
	cialist = System.listCIA()
	for k, v in pairs(cialist) do
		if v.unique_id == tonumber("0001A0300", 16) then
			System.launchCIA(tonumber("0001A0500", 16), SDMC)
		end
		if v.unique_id == tonumber("0001A0400", 16) then
			System.launchCIA(tonumber("0001A0500", 16), SDMC)
		end
		if v.unique_id == tonumber("0001A0500", 16) then
			System.launchCIA(tonumber("0001A0500", 16), SDMC)
		end
	end
end

--Main loop
--THISISANINDENTIFIERSOICANCONTROLFTOTHEMAINLOOP
while true do
	--Each menu has a value, different actions result in changing the menu value
	--Menus:
	--Main menu:0, Submit:1, Submit(part 2):2, Submit(part 3):3, Submit(success):4,
	--Submit(you haven't beat the level):5, Browse(not implemented):6, Will be used for brose:
	--7/8/9/10, Download:11, Download(part 2):12, Download(success):13
	--There are also "menu-ish"s that aren't technically menus but they are. They occupy the negative menu IDs
	--Configuration file checking/generation:-1, file_select:-2, keyInput:-3

	pre_update()

	if menu == 0 then
		--Main menu gfx
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			menu = 1
			controldelay = 15
			laf()
		end
		if (Controls.check(input,KEY_B)) and controldelay == 0 then
			menu = 6
			controldelay = 15
			laf()
		end
		if (Controls.check(input,KEY_Y)) and controldelay == 0 then
			menu = 11
			controldelay = 15
			laf()
		end
		if (Controls.check(input,KEY_R)) and controldelay == 0 then
			launchgame()
			controldelay = 15
		end
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			laf()
			Socket.term()
			Graphics.term()
			System.exit()
		end
	end

	if menu == 1 then
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			Console.clear(tconsole)
			uploadcoursename = keyInput("Enter your course's name")
			controldelay = 15
			table.insert(conditions, "pathed")
			laf()
		end
		if (Controls.check(input,KEY_B)) and controldelay == 0 then
			uploadcoursepath = file_select(true, "Select a course to upload")
			controldelay = 15
			table.insert(conditions, "named")
			laf()
		end
		if checkforval(conditions, "named", nil) and checkforval(conditions, "pathed", nil) and (Controls.check(input,KEY_Y)) and controldelay == 0 then
			uploadcoursefile = nil
			idpartrandom = nil
			math.randomseed(tonumber(string.byte(uploadcoursename)))
			idpartrandom = tostring(math.random(1000, 9999))
			menu = 2
			laf()
		end
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			menu = 0
			controldelay = 15
			uploadcoursefile = nil
			uploadcoursename = nil
			uploadcoursepath = nil
			conditions = {}
			leveldata = nil
			totallen = nil
			idpartrandom = nil
			laf()
		end
	end

	if menu == 2 then
		update()
		uploadcoursefile = io.open(uploadcoursepath, FREAD, 6660)
		leveldata = io.read(uploadcoursefile, 0, 274460)
		io.close(uploadcoursefile, true)
		table.insert(conditions, "read")
		update()
		uploadcoursefile = nil
		collectgarbage()
		leveldata = leveldata:tohex()
		leveldata = string.sub(leveldata, 0, 32) .. "0000000000000000" .. string.sub(leveldata, 49, #leveldata)
		-- There was an original plan to compress the data before sending it to the server but
		-- I ran into some server-side problems so I ditched the idea
		--------------------------------------
		-- comprezed = compress(leveldata)
		-- update_console("\n" .. #leveldata .. " bytes compressed to " .. #comprezed .. " bytes", tconsole)
		-- leveldata = nil
		-- collectgarbage()
		menu = 3
		laf()
		conditions = {}
	end

	if menu == 3 then
		update()
		emailcounter = 1
		emailcounter2 = 1
		totallen = 0
		length = #leveldata
		if string.sub(leveldata, 280, 280) ~= "1" then
			menu = 5
		else
			table.insert(conditions, "verified")
			update()
			lengthseg = length // 100
			lengthseg = lengthseg - 1
			while emailcounter2 <= 100 do
				-- Part of the compression plan
				-- tts = table.concat(comprezed, ",", emailcounter, emailcounter + lengthseg)
				tts = string.sub(leveldata, emailcounter, emailcounter + lengthseg)
				totallen = totallen + string.len(tts)
				emailcounter = emailcounter + lengthseg + 1
				requeststring = "http://" .. configip .. "/data_receive.php?n=" .. uploadcoursename .. idpartrandom .. "&d=" .. tts
				Network.requestString(requeststring)
				emailcounter2 = emailcounter2 + 1
				pre_update()
				Screen.fillRect(110, 141, 187, 210, yellow, BOTTOM_SCREEN)
				Screen.debugPrint(115, 195, emailcounter2, black, BOTTOM_SCREEN)
				post_update()
			end
			diff = #leveldata - lengthseg * 100
			if diff > 0 then
				-- Part of the compression plan
				-- tts = table.concat(comprezed, ",", nodifftotal, nodifftotal + diff)
				tts = string.sub(leveldata, emailcounter, #leveldata)
				totallen = totallen + string.len(tts)
				requeststring = "http://" .. configip .. "/data_receive.php?n=" .. uploadcoursename .. idpartrandom .. "&d=" .. tts
				Network.requestString(requeststring)
				update_console(";", tconsole)
			end
			-- The POST doesn't work :(
			-- post("data_receive.php", "n=" .. uploadcoursename .. idpartrandom .. "&d=" .. leveldata)
			-- Alternate idea for POST(Also doesn't work, even though it should work more than the first thing):
			-- requeststring = "http://" .. configip .. "/data_receive.php"
			-- data2post = "n=dfs" .. uploadcoursename .. idpartrandom .. "&d=" .. leveldata
			-- Network.requestString(requeststring, "foo", POST_METHOD, data2post)
			update_console("Done", tconsole)
			menu = 4
		end
		laf()
	end

	if menu == 4 then
		Screen.debugPrint(60, 155, uploadcoursename .. idpartrandom, black, BOTTOM_SCREEN)
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			menu = 0
			controldelay = 15
			uploadcoursefile = nil
			uploadcoursename = nil
			uploadcoursepath = nil
			pathed = nil
			named = nil
			leveldata = nil
			totallen = nil
			idpartrandom = nil
			collectgarbage()
			laf()
		end
	end

	if menu == 5 then
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			menu = 0
			controldelay = 15
			uploadcoursefile = nil
			uploadcoursename = nil
			uploadcoursepath = nil
			pathed = nil
			named = nil
			leveldata = nil
			idpartrandom = nil
			collectgarbage()
			laf()
		end
	end

	if menu == 6 then
		update_console(bconsole, "This feature is not yet ready!")
		update_console(bconsole, "\nPress X to return")
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			menu = 0
			controldelay = 15
		end
		Console.show(bconsole)
	end

	if menu == 11 then
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			menu = 0
			controldelay = 15
			downloadcoursefile = nil
			downloadcoursename = nil
			downloadcoursepath = nil
			pathed = nil
			named = nil
			collectgarbage()
			laf()
		end
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			downloadcoursename = keyInput("Enter the ID for the course")
			controldelay = 15
			table.insert(conditions, "named")
		end
		if (Controls.check(input,KEY_B)) and controldelay == 0 then
			downloadcoursepath = file_select(true, "Select a course to replace with the downloaded one")
			controldelay = 15
			table.insert(conditions, "pathed")
		end
		if checkforval(conditions, "named", nil) and checkforval(conditions, "pathed", nil) and (Controls.check(input,KEY_Y)) and controldelay == 0 then
			downloadcoursefile = nil
			menu = 12
			conditions = {}
			laf()
		end
	end

	if menu == 12 then
		update()
		--This is downloading a course. Probably the most documented code in the file
		--Gets list of valid ids from the server
		idlist = Network.requestString("http://" .. configip .. "/" .. "id_list.php")
		--looks for the entered id in the valid id list
		if string.find(idlist, downloadcoursename) ~= nil then
			--If the id is valid, continue downloading
			--get the file from the server
			table.insert(conditions, "verified")
			update()
			coursedownload = Network.downloadFile("http://" .. configip .. "/" .. downloadcoursename, "/SMMOCM/coursedownload")
			menu = 13
			conditions = {}
		else
			menu = 14
		end
		laf()
	end

	if menu == 13 then
		update()
		--open the required files
		newlevel = io.open("/SMMOCM/coursedownload", FREAD)
		configfile = io.open("/SMMOCM/config.txt", FCREATE)
		--read the data from the downloaded file
		newleveldata = io.read(newlevel, 0, io.size(newlevel))
		--read the LockoutID from the config file so the course will work
		configdata = io.read(configfile, 0, io.size(configfile))
		--closing the files, we just needed a little data
		io.close(newlevel)
		io.close(configfile)
		--getting the data up to the LockoutID, injecting the user's LockoutID, getting the data
		--up to where whether the course has been cleared is stored and then setting that to false
		--and getting the remaining data
		newleveldata = string.sub(newleveldata, 0, 16) .. configdata .. string.sub(newleveldata, 25, 279) .. string.char(00) .. string.sub(newleveldata, 280, #newleveldata)
		table.insert(conditions, "injected")
		update()
		--opening the course file to inject the new course into
		downloadcoursefile = io.open(downloadcoursepath, FWRITE, 6660)
		--writing the new course data
		io.write(downloadcoursefile, 0, newleveldata, #newleveldata)
		--cleaning up and moving to the success screen
		io.close(downloadcoursefile, true)
		menu = 15
		laf()
		conditions = {}
	end

	if menu == 14 then
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			--cleaning up
			downloadcoursefile = nil
			downloadcoursename = nil
			downloadcoursepath = nil
			pathed = nil
			named = nil
			newleveldata = nil
			configdata = nil
			newlevel = nil
			configfile = nil
			collectgarbage()
			menu = 0
			laf()
		end
	end

	if menu == 15 then
		--When a course has been successfully downloaded this screen appears
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			--cleaning up
			downloadcoursefile = nil
			downloadcoursename = nil
			downloadcoursepath = nil
			pathed = nil
			named = nil
			newleveldata = nil
			configdata = nil
			newlevel = nil
			configfile = nil
			collectgarbage()
			menu = 0
			laf()
		end
	end

	post_update()
end
