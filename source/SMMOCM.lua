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

--function that updates the console (top or bottom) in one line rather than 8
function update_console(message, console)
	Screen.waitVblankStart()
	Screen.refresh()
	Screen.clear(BOTTOM_SCREEN)
	Screen.clear(TOP_SCREEN)
	Console.append(console, message)
	Console.show(tconsole)
	Console.show(bconsole)
	Screen.flip()
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
	Console.clear(tconsole)
	Console.clear(bconsole)
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
		Screen.waitVblankStart()
		Screen.refresh()
		Screen.clear(BOTTOM_SCREEN)
		Screen.clear(TOP_SCREEN)
		
		curfile = files[fileselectnum]
		
		Console.append(bconsole, curfile.name)
		Console.append(tconsole, toptext)
		
		-- Console.append(bconsole, extdata_files)
		Console.show(bconsole)
		Console.show(tconsole)
		
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
		
		Screen.flip()
		Console.clear(bconsole)
		Console.clear(tconsole)
		
		if controldelay > 0 then
			controldelay = controldelay - 1
		end
	end
	return resultfile
end

--Checking for config file, this is what happens if it exists
if System.doesFileExist("/SMMOCM/config.txt") then
	configfile = io.open("/SMMOCM/config.txt", FREAD)
	--get the server ip from the config file
	configip = io.read(configfile, 8, io.size(configfile))
	io.close(configfile)
	--getting ready for main menu
	menu = 0
end

--Checking for config file, this is what happens if it doesn't exist
if System.doesFileExist("/SMMOCM/config.txt") == false then
	--getting a course file so we can extract the LockoutID
	lockidfile = io.open(file_select(true, "Config file does not exist, creating one\nPlease choose a course that youve created"), FREAD, 6660)
	--creating the config file
	configfile = io.open("/SMMOCM/config.txt", FCREATE)
	--I know I could have used 2 variables, but I used one for some reason to make it harder on myself
	lockidcharnum = 16
	--iterating over 0x10 to 0x17 to get the LockoutID, and writing it to the config file
	while lockidcharnum < 24 do
		io.write(configfile, lockidcharnum-16, io.read(lockidfile, lockidcharnum, 1), 1)
		lockidcharnum = lockidcharnum + 1
	end
	--clearing the consoles for server ip entry
	Console.clear(tconsole)
	Console.clear(bconsole)
	update_console("Enter the IP address of your server:", tconsole)
	--getting the server ip from the user
	configip = System.startKeyboard()
	--writing the ip the config file
	io.write(configfile, 8, configip, #configip + 8)
	--clean up
	io.close(lockidfile)
	io.close(configfile)
	--getting ready for main menu
	menu = 0
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

function post(path, data)
	--Creating socket
	socket_client = Socket.connect(configip, 80)
	--POST headers
	Socket.send(socket_client, "POST /" .. path .. "HTTP/1.0\r\n")
	--POST data
	Socket.send(socket_client, data)
	--Closing socket
	Socket.close(socket_client)
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

--Main loop

while true do
	--Screen initialization
	Screen.waitVblankStart()
	Screen.refresh()
	Screen.clear(BOTTOM_SCREEN)
	Screen.clear(TOP_SCREEN)
	
	--Reading user input
	input = Controls.read()
	
	--Each menu has a value, different actions result in changing the menu value
	--Menus:
	--Main menu:0, Submit:1, Submit(part 2):2, Submit(part 3):3, Submit(success):4,
	--Submit(you haven't beat the level):5, Browse(not implemented):6, Will be used for brose:
	--7/8/9/10, Download:11, Download(part 2):12, Download(success):13
	if menu == 0 then	
		Console.append(tconsole, "Welcome to SuperMarioMakerOnline\nCourseManager(SMMOCM)")
		Console.append(bconsole, "Please select an option:")
		Console.append(bconsole, "\nA: Submit a course")
		Console.append(bconsole, "\nB: Browse courses")
		Console.append(bconsole, "\nY: Download a course using ID")
		Console.append(bconsole, "\nX: Exit")
		Console.show(bconsole)
		Console.show(tconsole)
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			menu = 1
			controldelay = 15	
		end
		if (Controls.check(input,KEY_B)) and controldelay == 0 then
			menu = 6
			controldelay = 15
		end
		if (Controls.check(input,KEY_Y)) and controldelay == 0 then
			menu = 11
			controldelay = 15
		end
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			Socket.term()
			System.exit()
		end
	end
	
	if menu == 1 then
		Console.append(tconsole, "Submit a course")
		Console.append(bconsole, "Press A to choose a course")
		Console.append(bconsole, "\nPress B to name the course")
		if pathed and named then
			Console.append(bconsole, "\nPress Y to upload")
		end
		Console.append(bconsole, "\nPress X to return")
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			Console.clear(tconsole)
			uploadcoursepath = file_select(true, "Select a course to upload")
			controldelay = 15
			pathed = true
		end
		if (Controls.check(input,KEY_B)) and controldelay == 0 then
			uploadcoursename = System.startKeyboard()
			controldelay = 15
			named = true
		end
		if pathed and named and (Controls.check(input,KEY_Y)) and controldelay == 0 then
			uploadcoursefile = nil
			idpartrandom = nil
			math.randomseed(tonumber(string.byte(uploadcoursename)))
			idpartrandom = tostring(math.random(1000, 9999))
			menu = 2
		end
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
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
		end
		Console.show(tconsole)
		Console.show(bconsole)
	end
	
	if menu == 2 then
		update_console("\nReading Course...", tconsole)
		uploadcoursefile = io.open(uploadcoursepath, FREAD, 6660)
		leveldata = io.read(uploadcoursefile, 0, 274460)
		io.close(uploadcoursefile, true)
		update_console("Done", tconsole)
		uploadcoursefile = nil
		collectgarbage()
		update_console("\nFormatting Course Data...", tconsole)
		-- There was an original plan to compress the data before sending it to the server but
		-- I ran into some server-side problems so I ditched the idea
		--------------------------------------
		-- comprezed = compress(leveldata)
		-- update_console("\n" .. #leveldata .. " bytes compressed to " .. #comprezed .. " bytes", tconsole)
		-- leveldata = nil
		-- collectgarbage()
		menu = 3
	end
	
	if menu == 3 then
		emailcounter = 1
		emailcounter2 = 1
		totallen = 0
		leveldata = leveldata:tohex()
		leveldata = string.sub(leveldata, 0, 32) .. "0000000000000000" .. string.sub(leveldata, 49, #leveldata)
		length = #leveldata
		update_console("Done", tconsole)
		update_console("\nVerifying course is beatable...", tconsole)
		if string.sub(leveldata, 280, 280) ~= "1" then
			menu = 5
			Console.clear(tconsole)
			Console.clear(bconsole)
		else
			update_console("Done", tconsole)
			lengthseg = length // 100
			lengthseg = lengthseg - 1
			update_console("\nUploading", tconsole)
			while emailcounter2 <= 100 do
				-- Part of the compression plan
				-- tts = table.concat(comprezed, ",", emailcounter, emailcounter + lengthseg)
				tts = string.sub(leveldata, emailcounter, emailcounter + lengthseg)
				totallen = totallen + string.len(tts)
				update_console(".", tconsole)
				emailcounter = emailcounter + lengthseg + 1
				Network.requestString("http://" .. configip .. "/" .. "data_receive.php?n=" .. uploadcoursename .. idpartrandom .. "&d=" .. tts)
				emailcounter2 = emailcounter2 + 1
				update_console(".", tconsole)
			end
			diff = #leveldata - lengthseg * 100
			if diff > 0 then
				-- Part of the compression plan
				-- tts = table.concat(comprezed, ",", nodifftotal, nodifftotal + diff)
				tts = string.sub(leveldata, emailcounter, #leveldata)
				totallen = totallen + string.len(tts)
				Network.requestString("http://" .. configip .. "/" .. "data_receive.php?n=" .. uploadcoursename .. idpartrandom .. "&d=" .. tts)
				update_console(";", tconsole)
			end
			update_console("Done", tconsole)
			menu = 4
			Console.show(tconsole)
			Console.show(bconsole)
		end
	end
	
	if menu == 4 then
		Console.append(tconsole, "Your course has been submitted!")
		Console.append(tconsole, "\nIt being processed and will be\nable to be downloaded within a day")
		Console.append(tconsole, "\n---------------------------------")
		Console.append(tconsole, "\nHere your course ID, don't lose it!")
		Console.append(tconsole, "\nIt is not saved so write it down!")
		Console.append(tconsole, "\nPress A when you are done")
		Console.append(bconsole, uploadcoursename .. idpartrandom)
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
		end
		Console.show(tconsole)
		Console.show(bconsole)
	end
	
	if menu == 5 then
		Console.clear(tconsole)
		Console.clear(bconsole)
		Console.append(tconsole, "Sorry, but you cannot upload this course")
		Console.append(tconsole, "\nPlease clear the course and then upload it")
		Console.append(tconsole, "\nPress A to return")
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
		end
		Console.show(tconsole)
	end
	
	if menu == 6 then
		Console.append(bconsole, "This feature is not yet ready!")
		Console.append(bconsole, "\nPress X to return")
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			menu = 0
			controldelay = 15
		end
		Console.show(bconsole)
	end
	
	if menu == 11 then
--		Network.downloadFile(string url,string filename)
		Console.append(tconsole, "Download course by ID")
		Console.append(bconsole, "Press A to select course to replace")
		Console.append(bconsole, "\nPress B to enter the course ID")
		if pathed and named then
			Console.append(bconsole, "\nPress Y to download the course")
		end
		Console.append(bconsole, "\nPress X to return")
		if (Controls.check(input,KEY_X)) and controldelay == 0 then
			menu = 0
			controldelay = 15
			downloadcoursefile = nil
			downloadcoursename = nil
			downloadcoursepath = nil
			pathed = nil
			named = nil
			collectgarbage()
		end
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
			Console.clear(tconsole)
			downloadcoursepath = file_select(true, "Select a course to replace with the downloaded one")
			controldelay = 15
			pathed = true
		end
		if (Controls.check(input,KEY_B)) and controldelay == 0 then
			downloadcoursename = System.startKeyboard()
			controldelay = 15
			named = true
		end
		if pathed and named and (Controls.check(input,KEY_Y)) and controldelay == 0 then
			downloadcoursefile = nil
			menu = 12
		end
		Console.show(bconsole)
		Console.show(tconsole)
	end
	
	if menu == 12 then
		--This is part 2 of downloading a course. Probably the ugliest code in the file
		update_console("\nVerifying course ID...", tconsole)
		--Gets list of valid ids from the server
		idlist = Network.requestString("http://" .. configip .. "/" .. "id_list.php")
		--looks for the entered id in the valid id list
		if string.find(idlist, downloadcoursename) ~= nil then
			--If the id is valid, continue downloading
			update_console("\nCourse ID verified.\nDownloading...", tconsole)
			--get the file from the server
			coursedownload = Network.downloadFile("http://" .. configip .. "/" .. downloadcoursename, "/SMMOCM/coursedownload")
			update_console("\nCourse Downloaded!\nInjecting LockoutID...", tconsole)
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
			update_console("\nInjecting Course...", tconsole)
			--opening the course file to inject the new course into
			downloadcoursefile = io.open(downloadcoursepath, FWRITE, 6660)
			--writing the new course data
			io.write(downloadcoursefile, 0, newleveldata, #newleveldata)
			--cleaning up and moving to the success screen
			io.close(downloadcoursefile, true)
			menu = 13
		else
			--If the id is invalid, tell the user and make them L+R+DPAD_DOWN+B
			--Sorry.
			--(sorry to those ppl who don't know the L+R+DPAD_DOWN+B trick, it's super 
			--useful so you don't have to reboot when homebrew apps freeze or crash as they often do.)
			
			update_console("\nInvalid course ID!", tconsole)
			while true do
			end
		end
	end
	
	if menu == 13 then
		--When a course has been successfully downloaded this screen appears
		Console.clear(tconsole)
		Console.clear(bconsole)
		update_console(tconsole, "The course has been downloaded!")
		update_console(tconsole, "\nHave fun!")
		Console.append(tconsole, "\n(Press A to return)")
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
		end
		Console.show(bconsole)
		Console.show(tconsole)
	end
	
	--flushing all changes to the screen
	Screen.flip()
	
	--clearing the consoles
	Console.clear(bconsole)
	Console.clear(tconsole)
	--decreasing the controldelay so you can input stuff again
	if controldelay > 0 then
		controldelay = controldelay - 1
	end
end