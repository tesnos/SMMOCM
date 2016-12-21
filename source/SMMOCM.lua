bconsole = Console.new(BOTTOM_SCREEN)
tconsole = Console.new(TOP_SCREEN)
menu = -1
controldelay = 0
configtimer = 0
uploadcoursefile = nil
uploadcoursename = nil
uploadcoursepath = nil
named = nil
pathed = nil
downloadcoursename = nil
downloadcoursepath = nil
idlistpath = "/SMMOCM/idlist.txt"

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

-- this function is code "borrowed" from stackoverflow :P

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

hexdict = {[0]='0', [1]='1', [2]='2', [3]='3', [4]='4', [5]='5', [6]='6', [7]='7', [8]='8', [9]='9', [10]='A', [11]='B', [12]='C', [13]='D', [14]='E', [15]='F'}

function string.tohex(str)
    return (str:gsub('.', function (c)
		m = string.byte(c) // 16
		t = 16 * m
		r = string.byte(c) - t
        return string.format(hexdict[m] .. hexdict[r])
    end))
end

-- this is from https://gist.github.com/yi/01e3ab762838d567e65d

function string.fromhex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16))
    end))
end

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

if System.doesFileExist("/SMMOCM/config.txt") then
	configfile = io.open("/SMMOCM/config.txt", FREAD)
	configip = io.read(configfile, 8, io.size(configfile))
	io.close(configfile)
	menu = 0
end

if System.doesFileExist("/SMMOCM/config.txt") == false then
	lockidfile = io.open(file_select(true, "Config file does not exist, creating one\nPlease choose a course that youve created"), FREAD, 6660)
	configfile = io.open("/SMMOCM/config.txt", FCREATE)
	lockidcharnum = 16
	progress = 0
	while lockidcharnum < 24 do
		io.write(configfile, lockidcharnum-16, io.read(lockidfile, lockidcharnum, 1), 1)
		lockidcharnum = lockidcharnum + 1
	end
	Console.clear(tconsole)
	Console.clear(bconsole)
	update_console("Enter the IP address of your server:", tconsole)
	configip = System.startKeyboard()
	io.write(configfile, 8, configip, #configip + 8)
	io.close(lockidfile)
	io.close(configfile)
	menu = 0
end

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
			--update_console("\nInserted: " .. w, tconsole)
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

while true do

	Screen.waitVblankStart()
	Screen.refresh()
	Screen.clear(BOTTOM_SCREEN)
	Screen.clear(TOP_SCREEN)
	
	input = Controls.read()
	
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
		update_console("\nVerifying course ID...", tconsole)
		idlist = Network.requestString("http://" .. configip .. "/" .. "id_list.php")
		update_console("\n" .. idlist, tconsole)
		if string.find(idlist, downloadcoursename) ~= nil then
			update_console("\nCourse ID verified.\nDownloading...", tconsole)
			coursedownload = Network.downloadFile("http://" .. configip .. "/" .. downloadcoursename, "/SMMOCM/coursedownload")
			update_console("\nCourse Downloaded!\nInjecting LockoutID...", tconsole)
			newlevel = io.open("/SMMOCM/coursedownload", FREAD)
			configfile = io.open("/SMMOCM/config.txt", FCREATE)
			newleveldata = io.read(newlevel, 0, io.size(newlevel))
			configdata = io.read(configfile, 0, io.size(configfile))
			io.close(newlevel)
			io.close(configfile)
			newleveldata = string.sub(newleveldata, 0, 16) .. configdata .. string.sub(newleveldata, 25, 279) .. string.char(00) .. string.sub(newleveldata, 280, #newleveldata)
			update_console("\nInjecting Course...", tconsole)
			downloadcoursefile = io.open(downloadcoursepath, FWRITE, 6660)
			io.write(downloadcoursefile, 0, newleveldata, #newleveldata)
			io.close(downloadcoursefile, true)
			menu = 13
		else
			update_console("\nInvalid course ID!", tconsole)
			while true do
			end
		end
	end
	
	if menu == 13 then
		Console.clear(tconsole)
		Console.clear(bconsole)
		update_console(tconsole, "The course has been downloaded!")
		update_console(tconsole, "\nHave fun!")
		Console.append(tconsole, "\n(Press A to return)")
		if (Controls.check(input,KEY_A)) and controldelay == 0 then
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
	
	Screen.flip()
	
	Console.clear(bconsole)
	Console.clear(tconsole)
	if controldelay > 0 then
		controldelay = controldelay - 1
	end
	
end