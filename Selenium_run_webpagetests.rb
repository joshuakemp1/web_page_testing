require 'selenium-webdriver'
require 'crack'
require 'open-uri'
# require 'net/http'
require 'nokogiri'
#Config variables
@xml_urls = []
@email_body = ""
@email_data = ""
@outputStr = ""
@cleaned_outputStr = ""
@num_runs = 3
@devices = []
@unit = 1000 # time in milliseconds
@unit_bytes = 1024
@base_Path = "/Users/joshuakemp/josh/scripts/"
@client_name = "wikipedia"
@webpagetest_devices = []
# Variable for the path
@waitForXMLResult = 10
@file_print_location = "#{@base_Path}Output_for_webpagetest_results/#{@client_name}/"
@devices_File = "/Users/joshuakemp/josh/scripts/selenium_devices_for_webpagetest.txt" #format is one device per line  IE 11 then next line Nexus 7 - Chrome
#@username = "" # This is where you pass in basic auth 
#@password = "" # and password to web page test
@failed_urls = []
@which_device_failed = []
#End config variables#####

######################### Initializing variables this will let me know if a field was not available when I import it to the spreadsheet
@test_url = "None"
@this_url_filename = "None"
@completed_time = "None"
@median_loadtime = "None"
@median_TTFB ="None"
@median_start_render = "None"
@median_speed_index = "None"
@median_dom_elements = "None"
@median_dc_time = "None"
@median_dc_requests = "None"
@median_dc_bytes_in = "None"
@median_fl_time = "None"
@median_fl_requests = "None"
@median_fl_bytes_in = "None"
@test_device = "None"
########################

@urls = []
 inFile = File.open("#{@base_Path}selenium_webpagetest_urls.txt", "r")
 # inFile = File.open("#{@base_Path}jjtest.txt", "r")

 while (line = inFile.gets)
     @urls << line.to_s.chomp

 end
#Checking the devices file matches the web page test site#########
@devices_file = File.open("#{@devices_File}", "r")
 while (line = @devices_file.gets)
     @devices << line.to_s.chomp unless line.include? "#" #Don't include any lines that are commented
 end

    puts "Going out with Nokogiri!"
    page_src_2 = Nokogiri::HTML(open("http://www.webpagetest.org/"))
    puts "Grabbing the @browsers variable"
    @browsers = page_src_2.css("select#browser").children.text.gsub("  ", "").gsub("\r","").split("\n")
    @browsers = @browsers.delete_if { |str| str.empty? }

  for i in (0..@browsers.count-1)
    puts @browsers[i]
    @webpagetest_devices << @browsers[i]
  end

  for d in (0..@devices.count-1)
    if @webpagetest_devices.include?(@devices[d]) then
        puts "#{@devices[d]} is present!"
    else
      puts "Device: #{@devices[d]} doesn't not exist in web page test devices"
    end
  end
#End Checking the devices file matches the web page test site#########

  for i in (0..@devices.length-1)
      puts "Testing these DEVICES [#{i+1}] : [" + @devices[i].to_s.chomp + "]" #print put urls in array and trim \n
  end
# Taking the webpagetest list of test URLS and then using gsub to make each test URL into a txt file with the same name
def getClientOutputFileName(url) #function to get the <clientdomain>.com text. This one will handle <subdomain>.<domain>.com/<section>
  @newStr=url.to_s.chomp.gsub("http://", "").gsub("https://", "").gsub("www.", "").gsub("/", "-")
  if (@newStr.end_with? "/") then @newStr=@newStr.chop! end
  if (@newStr.end_with? "-") then @newStr=@newStr.chop! end
  @newStr+=".txt"
  return @newStr
end

# Making the webpagetest URLS broken down by device
def getClientOutputFileName_device(filename,device)
    puts "Device: #{device}"
    puts "Filename: #{filename}"
    @newStr = filename.chomp.to_s.gsub(".txt", "__#{device}.txt").gsub(" ", "")
    puts "Device filename: #{@newStr}"
    return @newStr
end
 for i in (0..@urls.length-1)
    puts "Testing these URLS [#{i+1}] : " + @urls[i].to_s.chomp #print put urls in array and trim \n
 end

sleep 1.5

 inFile.close
    @timeStamp=Time.now.strftime("%m-%d-%Y__%I_%M_%p_%Ss").to_s
    @driver = Selenium::WebDriver.for :firefox, :profile => 'default'

for i in (0..@urls.length-1)
    print "#{@urls[i]}|"
    puts "File name for this URL will be: #{@this_url_filename}"
  for d in(0..@devices.length-1)
    puts "device: #{@devices[d]}"
    begin
      @driver.navigate.to "http://www.webpagetest.org/"
      sleep 1
      if i == 0 then
        if @driver.find_element(:css, 'input#viewFirst').displayed? then
          puts 'I see view first!'
          puts 'Clicking the First view!'
          sleep 1
          @driver.find_element(:css, 'input#viewFirst').click
          puts 'Tests are running as first view!'
        if @driver.find_element(:css, 'input#number_of_tests').displayed? then
          puts 'Advanced tab already displayed'
        else
          element = @driver.find_element(:css, '#advanced_settings').click
        end
        end
      end
      sleep 1


      if @driver.find_element(:css, '#test_subbox-container > ul > li:nth-child(1) > a').
        displayed? then
        puts "I see the Test Settings tab!"
        element = @driver.find_element(:css, '#test_subbox-container > ul > li:nth-child(1) > a')
        element.click()
        puts "Clicking on the Test Settings tab!"
      else
        puts "I don't see the Test Settings tab!!!"
      end
# Now clearing the input fields for the AUTH and entering in the username and password

      if @driver.find_element(:css, '#url').displayed? then
        element = @driver.find_element(:css, '#url')
      else
        puts "Cannot find #url element!"
      end
          puts "attempting to clear URL input!"
          element.clear()
          puts "Cleared URL input!"
          element.send_keys "#{@urls[i]}"
            puts "looking for test numbers for #{@devices[d]}"
          input_runs = @driver.find_element(:css, 'input#number_of_tests')
          puts "attempting to clear"
          input_runs.clear()
          puts "attempting to send"
          input_runs.send_keys(@num_runs.to_i)

      # Looking for the AUTH tab and verifying that it exists
      if @driver.find_element(:css, '#test_subbox-container > ul > li:nth-child(4) > a').
        displayed? then
        puts "I see the AUTH tab!"
        element = @driver.find_element(:css, '#test_subbox-container > ul > li:nth-child(4) > a')
        element.click()
        puts "Clicking on the AUTH tab!"
        # # Now clearing the input fields for the AUTH and entering in the username and password
            puts "attempting to clear the AUTH username"
            username = @driver.find_element(:css, '#username')
            username.clear()
            puts "attempting to send AUTH username"
            username.send_keys("#{@username}")
            # now clearing password
            puts "attempting to clear the AUTH password"
            password = @driver.find_element(:css, '#password')
            password.clear()
            puts "attempting to send AUTH password"
            password.send_keys("#{@password}")
# This is the end of the username and password for AUTH
# Now go back to the Test Settings tab
      else
        puts "NO AUTH!!!"
      end
# Looking for the AUTH tab and verifying that it exists

      if @devices[d] == "Nexus 5 - Chrome"
        @chrome_tab = @driver.find_element(:css, "#test_subbox-container > ul > li:nth-child(3) > a")
        if @chrome_tab.displayed? then
          puts "Found the Chrome Tab!"
          @chrome_tab.click
          @emulator = @driver.find_element(:css, 'input#mobile.checkbox')
          if @emulator.displayed? then
            puts "Found the Emulator!"
            @emulator.click
            puts "Clicking the Emulator!"
            else
              puts "Cannot find the Emulator :-("
          end
        else
          puts "Cannot find Chrome Tab :-("
        end
      end
    sleep 1
        puts 'looking for browser'
        input_browser_type = @driver.find_element(:name, 'browser')
        sleep 0.5
        puts "attempting to send device: #{@devices[d].chomp}"
        input_browser_type.send_keys "#{@devices[d].chomp}"
        sleep 0.5
          puts 'looking for submit button'
        @driver.find_element(:name, 'submit').click
        sleep 2
          print "result url: " + @driver.current_url + "\n"
          @resulting_url = @driver.current_url
        @xml_url = @driver.current_url.gsub("result", "xmlResult").to_s.chomp
        @xml_urls << @xml_url
# for hash map xmlResult Url device
          puts "This URL: #{@urls[i]}"
          puts "This URLs xml_url: #{@xml_url}"
          puts
          puts "Univision Web page tests are now starting"
          puts
          puts "#{@devices[d]} test is starting"
          puts "#{i+1} of #{@urls.length} input urls started"

    rescue Exception=>e
      puts "\n**Got an Exception: " + e.to_s
    end# end begin rescue loop
  end#end devices loop
end#end urls loop
@driver.quit

    for i in (0..@xml_urls.length-1)
        puts @xml_urls[i]
    end# Prints out the xml urls

    for i in (0..@xml_urls.length-1)
      @xml_url = @xml_urls[i]
      uri = URI.parse(URI.encode(@xml_url))
      response = Net::HTTP.get(URI(uri))#Send web page test request
      parsed_res = Crack::XML.parse(response)#Parse web page test response
      status = parsed_res["response"]["statusCode"]# Assigns the HTTP code to status
      puts "status: " + status

      until (status.to_i == 200) do
        puts "Status Code on getting xmlResult is: #{status.to_s}" #Todo fix this with a hash map
        puts "Sleeping #{@waitForXMLResult.to_s}..."
        sleep @waitForXMLResult.to_i#Waiting for 10 seconds

        uri = URI.parse(URI.encode(@xml_url))
        response = Net::HTTP.get(URI(uri))#Sending the web page test request again
        parsed_res = Crack::XML.parse(response)#Parse web page test response
        status = parsed_res["response"]["statusCode"]# Assigns the HTTP code to status
      end

          puts "Test #{i+1} for #{@xml_url} finished with Status Code: #{status}...\n"
          @thisURLResponseTime=Time.now.strftime("%m-%d-%Y__%I_%M_%p_%Ss").to_s
          puts "Attempting to retrieve data for this URL...#{@thisURLResponseTime}"

          @successfulFVRuns = parsed_res["response"]["data"]["successfulFVRuns"]# Checking to see that the test actually successfully ran

        begin
          if @successfulFVRuns.to_i < 1  then
            # Defining the var so that we can check to see if the test failed or not
            @test_url = parsed_res["response"]["data"]["testUrl"]
            # Defining the var so taht we can check to see which device the test url failed on
            @test_device = parsed_res["response"]["data"]["location"]
            # We have to split the and extract the 2nd element of the array to get the device type
            @test_device = @test_device.split(":")

            # Call the second element in the array
            # this_device is the devices: IE 11 , NExus 7 , NExus 5 for example
            @this_device = @test_device[1]
            puts "Test [#{@test_url.to_s}] has zero runs!!! ... it failed on this device: [#{@this_device.to_s}]!!!"
            # If there are any failed test urls we push them to the @failed_urls array so that we will be able to send them along in the email
            @failed_Str = "#{@test_url.to_s}, #{@this_device.to_s}"
            @failed_urls.push(@failed_Str)
            # If there are any failed test urls we want to push which device they failed on as well, so we push the device to the which_device_failed
            # @which_device_failed.push(@this_device)
            next
          end
            # Convert the the results to times that make more sense like seconds and Kilobytes
            # This is the original test URL reading it from the xmlResult
            @test_url = parsed_res["response"]["data"]["testUrl"]
            # This is the test URL that has been converted to the .txt on the end
            @this_url_filename = getClientOutputFileName("#{@test_url}")
            @completed_time = parsed_res["response"]["data"]["completed"]
            @median_loadtime = (parsed_res["response"]["data"]["median"]["firstView"]["loadTime"].to_f/@unit).to_s
            puts "Median First View - Load Time: #{@median_loadtime}\n"
            @median_TTFB = (parsed_res["response"]["data"]["median"]["firstView"]["TTFB"].to_f/@unit).to_s
            @median_start_render = (parsed_res["response"]["data"]["median"]["firstView"]["render"].to_f/@unit).to_s
            @median_speed_index = parsed_res["response"]["data"]["median"]["firstView"]["SpeedIndex"]
            @median_dom_elements = parsed_res["response"]["data"]["median"]["firstView"]["SpeedIndex"]
            @median_dc_time = (parsed_res["response"]["data"]["median"]["firstView"]["docTime"].to_f/@unit).to_s
            @median_dc_requests = parsed_res["response"]["data"]["median"]["firstView"]["requestsDoc"]
            @median_dc_bytes_in = (parsed_res["response"]["data"]["median"]["firstView"]["bytesInDoc"].to_f/@unit_bytes).round.to_s
            @median_fl_time = (parsed_res["response"]["data"]["median"]["firstView"]["fullyLoaded"].to_f/@unit).to_s
            @median_fl_requests = parsed_res["response"]["data"]["median"]["firstView"]["requests"]
            @median_fl_bytes_in = (parsed_res["response"]["data"]["median"]["firstView"]["bytesIn"].to_f/@unit_bytes).round.to_s

            @test_device = parsed_res["response"]["data"]["location"]
            # We have to split the and extract the 2nd element of the array to get the device type
            @test_device = @test_device.split(":")

            # Call the second element in the array
            # this_device is the devices: IE 11 , NExus 7 , NExus 5 for example
            @this_device = @test_device[1]

            puts "this device: #{@this_device}"
            puts "this url filename: #{@this_url_filename}"
            # We pass in the URL like http://www.google.com.txt and the device IE 11 for example so that it is converted to www.google.txt__IE11
            @device_filename = getClientOutputFileName_device(@this_url_filename, @this_device)
            puts "device filename: #{@device_filename}"

            @resultURL = @xml_url.gsub("xmlResult","result")

            #concatenate all fields into bigString
            @outputStr = "#{@thisURLResponseTime.to_s}|Device:#{@test_device[1]}|Requested URL:#{@test_url}|Result URL:#{@resultURL}|Result XML URL:#{@xml_url}|Completed Time:#{@completed_time}|Date:#{@thisURLResponseTime.to_s}|Load Time:#{@median_loadtime}|TTFB:#{@median_TTFB}|Start Render:#{@median_start_render}|Speed Index:#{@median_speed_index}|Dom Elements:#{@median_dom_elements}|DC Time:#{@median_dc_time}|DC Requests:#{@median_dc_requests}|DC Bytes:#{@median_dc_bytes_in}|FL Time:#{@median_fl_time}|FL Requests:#{@median_fl_requests}|FL Bytes:#{@median_fl_bytes_in}|\n"
            #This is the data all cleaned up for import into a spreadsheet
             @cleaned_outputStr = "#{@thisURLResponseTime.to_s}|#{@test_device[1]}|#{@test_url}|#{@resultURL}|#{@xml_url}|#{@completed_time}|#{@thisURLResponseTime.to_s}|#{@median_loadtime}|#{@median_TTFB}|#{@median_start_render}|#{@median_speed_index}|#{@median_dom_elements}|#{@median_dc_time}|#{@median_dc_requests}|#{@median_dc_bytes_in}|#{@median_fl_time}|#{@median_fl_requests}|#{@median_fl_bytes_in}|\n"

              puts "This is the scrubbed @the_device: #{@the_device}"
              puts "This is the scrubbed @requested_url: #{@requested_url}"
              puts "This is the scrubbed @result_url: #{@result_url}"
              puts "This is the scrubbed @xml_url: #{@xml_url}"
              puts "This is the scrubbed @completed_time: #{@completed_time}"
              puts "This is the scrubbed thisURLResponseTime: #{@thisURLResponseTime}"
              puts "This is the scrubbed median_loadtime: #{@median_loadtime}"
              puts "This is the scrubbed median_TTFB: #{@median_TTFB}"
              puts "This is the scrubbed median_start_render: #{@median_start_render}"
              puts "This is the scrubbed median_speed_index: #{@median_speed_index}"
              puts "This is the scrubbed median_dom_elements: #{@median_dom_elements}"
              puts "This is the scrubbed median_dc_time: #{@median_dc_time}"
              puts "This is the scrubbed median_dc_requests: #{@median_dc_requests}"
              puts "This is the scrubbed median_dc_bytes_in: #{@median_dc_bytes_in}"
              puts "This is the scrubbed median_fl_time: #{@median_fl_time}"
              puts "This is the scrubbed median_fl_requests: #{@median_fl_requests}"
              puts "This is the scrubbed median_fl_bytes_in: #{@median_fl_bytes_in}"

              # @cleaned_outputStr = @cleaned_outputStr.join('|')

              puts "OUTPUT STRING: #{@cleaned_outputStr}"

              # End of TEST CODE for clean up data
              # This is the data for that we are going to eventually use for Jenkins
              outFile = File.open("#{@base_Path}selenium_finished_data_for_spreadsheet.txt", "a")
              outFile.print("#{@outputStr}")
              #outFile_Spreadsheet()
              # this is where we would go and check the xmlResult URL for a 404.  If so then we wouldn't import to spreadsheet
              outFile.close

              # This is the where I save the cleaned up data so I can import it to Google spreadsheets
              @scrubbed_outfile = File.open("#{@base_Path}selenium_scrubbed_data_for_spreadsheet.txt", "a")
              @scrubbed_outfile.print("#{@cleaned_outputStr}")
              @scrubbed_outfile.close

              #Now send the results in an email to let me know it's finished running
              @email_data = "Device:#{@test_device[1]}\nTime:#{@thisURLResponseTime.to_s}\nRequested URL:#{@test_url}|\nResult URL: #{@resultURL} |Result XML URL:#{@xml_url}\nCompleted Time:#{@completed_time}|Load Time:#{@median_loadtime}|TTFB:#{@median_TTFB}| \n|start_render:#{@median_start_render.to_s}|speed_index:#{@median_speed_index.to_s}|document complete time:#{@median_dc_time.to_s}|document complete requests:#{@median_dc_requests.to_s}|document complete bytes_in:#{@median_dc_bytes_in.to_s}|fully loaded time:#{@median_fl_time.to_s}|fully loaded requests:#{@median_fl_requests.to_s}|fully loaded bytes in:#{@median_fl_bytes_in.to_s}|\n\n"

              @email_body += @email_data

      rescue Exception=>e
        puts "\n**Got an Exception: " + e.to_s
        # @email_body += "Time:#{@timeStamp.to_s}\nRequested URL:#{@test_url}|Error: #{e.to_s}\n"
        end# end begin rescue loop
    end# End loop for requesting xml from web page test

# Grabs the failes urls array and loops over the failed URLS and makes them into a string to send in the email
    puts "Number of failed URLS: [#{@failed_urls.count.to_s}]"
    @failedUrlsSTR = ""
    for i in (0..@failed_urls.length-1)
      @failedUrlsSTR += "failed url/device: #{@failed_urls[i]} \n\n"
    end

    puts @failedUrlsSTR

   puts "Sending email notification!"

   @emailSubject = "Selenium Web Page Test Complete"
   @outMessage = "Here is your data:\n\n #{@email_body.to_s} \n\n\ #{@failedUrlsSTR.to_s} \n\n\ #{@which_device_failedSTR.to_s}"

  begin
    # email body                            email subject
  `echo "#{@outMessage}" | mailx -s  "#{@emailSubject}" joshuakemp85@gmail.com -F "Josh - WEBPAGETEST COMPLETE" -f joshuakemp85@gmail.com`
  rescue Exception=>e
    puts "\n**Got an Exception trying to send email: " + e.to_s
  end# end begin email rescue loop