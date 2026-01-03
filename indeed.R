#installing and loading the packages : 
library(RSelenium)
library(httr)
library(XML)
library(rvest)

#start a Selenium Server and create a driver object for browser automation
rm.driver <- rsDriver(
  browser = "firefox",  #browser type to control
  phantomver = NULL, # Specifies the version of PhantomJS to use as NULL
  chromever = NULL) # Specifies the version of ChromeDriver as NULL since we use Firefox
rm <- rm.driver$client

# check session status
rm$getStatus() # if you got $ready[1] TRUE && $message [1] "Server is running" means it's working fine

#terminate session using cmd (this is how I terminate)
# C:\Users\ASUS>netstat -ano | findstr :4567
# TCP    0.0.0.0:4567           0.0.0.0:0              LISTENING       10244
# TCP    [::]:4567              [::]:0                 LISTENING       10244
# 
# C:\Users\ASUS>taskkill /PID 10244 /F
# SUCCESS: The process with PID 10244 has been terminated.

 ###=============================================== accepting cookies and login :) 

# Go to the Indeed sign-in page
rm$navigate('https://secure.indeed.com/')

#========================================================= COOKIES
# Wait until the cookies consent button is visible and accept cookies by clicking.
Sys.sleep(1)
cookies_button <- rm$findElement(using = 'id', "onetrust-accept-btn-handler")
cookies_button$clickElement()

#========================================================AUTHENTICATION 
# After accepting cookies, proceed with the login process
# Wait until abit for cookie process before login
Sys.sleep(1)
#enter the email on the textbox
email_input <- rm$findElement(using = 'css selector', 'input[type=email]')
email_input$sendKeysToElement(list("ir#######@gmail.com")) # enter your email

#sometimes it ask to varify that you are a human.
# maybe they might have capture me as a non-human activity :D


# Click the 'Continue' button after entering the email
Sys.sleep(5)
continue_button <- rm$findElement(using = 'css selector', 'button[type=submit]')
continue_button$clickElement()

# at this point qhen you enter your email and continue
# you have notice that the indeed account detect that you have been created account with google. 


##======================== continue with google account
#I had to follow this method since I am way to lay to create accounts with email and password
# I always choose to create accounts with google so I decided to follow this way of login.
#the... google login!

# there are two methods here either continue by varifying google account 
# or giving them the code that you will recieve into your email

#========================= varifying your google account

# Wait until the "Continue with Google" button is visible and then click it
Sys.sleep(1)
google_button <- rm$findElement(using = 'id', "gsuite-login-google-button")
google_button$clickElement()

# Get all window handles
window_handles <- rm$getWindowHandles()

# Switch to the new window, typically the last one in the list
rm$switchToWindow(window_handles[[length(window_handles)]])

#cofirming the google sign in wait for cloud fare button to load
Sys.sleep(3)
next_button <- rm$findElement(using = 'css selector', '[jsname="LgbsSe"]')
next_button$clickElement()

# for some reasons this code does not helped. even if i try to do it manually it gives an error saying:
# 'This browser or app may not be secure. Learn more'
# 'Try using a different browser. If you’re already using a supported browser, you can try again to sign in.'

##============================= Sign in with login code instead

# Click the "Sign in with login code instead" link
Sys.sleep(1)
login_code_link <- rm$findElement(using = 'css selector', "a[data-tn-element='auth-page-google-password-fallback']")
login_code_link$clickElement()

# Enter the 6-digit code you've received
Sys.sleep(1)
code_input <- rm$findElement(using = 'id', "passcode-input")
code <- "886356"  # actual code you received to your mail
code_input$sendKeysToElement(list(code))

# Click the 'Sign in' button after entering the code
# You would need to find the correct selector for the 'Sign in' button
Sys.sleep(1)
sign_in_button <- rm$findElement(using = 'css selector', "button[data-tn-element='otp-verify-login-submit-button']")
sign_in_button$clickElement()

#navigate to indeed site which shows all the USA jobs because I have trouble reading swedish :D
rm$navigate('https://www.indeed.com/q-usa-jobs.html')

# Find the search box by ID and clear the existing text which is "usa"
Sys.sleep(5)
input_box <- rm$findElement(using = 'id', value = 'text-input-what')
input_box$clearElement() 

# OR........... you can double click on the logo which navigate to job listing page. 
# why two times clicking ??? it shows a page in swedish asking somthing which i dont understand 
#when I click again it navigate to home page
# so don't forget to run the below code twice. 

# Find the Indeed logo using its class name and click it twice to navigate to the homepage
indeed_logo <- rm$findElement(using = 'css selector', 'a.gnav-Logo')
indeed_logo$clickElement()

# Find the search bar input fiels and enter "data analyst"
what_input <- rm$findElement(using = 'css selector', 'input[name="q"]')
what_input$sendKeysToElement(list("data analyst"))

# click on search button
search_form <- rm$findElement(using = 'css selector', 'form#jobsearch')
search_form$submitElement()

#time to scrape...... 

#====================================================== Let's scrape out data by iterating each page
# Wait for the page to load
Sys.sleep(3)

# Initialize a list to store job details
all_jobs <- list()

# there are so many jobs available in USA related to Data Analyst so we will only going to scrape first 5 pages.
# Iterate through each job container
for(page in 1:5){
  # Find all job containers
  job_containers <- rm$findElements(using = 'css selector', 'li.css-5lfssm.eu4oa1w0 > div.cardOutline')
  # it has 15 perfect each page got 15 job. 
  
  # Get the entire page source
  page_source <- rm$getPageSource()[[1]]
  
  # this is the regex pattern to extract the job URL
  pattern <- 'href="/rc/clk\\?jk=[^"]+"'
  
  # Extract job URLs using above regex pattern
  job_urls <- regmatches(page_source, gregexpr(pattern, page_source))[[1]]
  
for (i in seq_along(job_containers)) {
  count <- 1
  job_title <- job_containers[[i]]$findChildElement(using = "css selector", ".jobTitle")$getElementText()
  company_name <- job_containers[[i]]$findChildElement(using = "css selector", ".css-92r8pb")$getElementText()
  company_location <- job_containers[[i]]$findChildElement(using = "css selector", ".css-1p0sjhy")$getElementText()
  description <- job_containers[[i]]$findChildElement(using = "css selector", ".eu4oa1w0")$getElementText()
  
  # Create a list of job details
  job_details <- list(
    job_title = job_title,
    company_name = company_name,
    company_location = company_location,
    description = description,
    job_url = job_urls[i]
  )
  
  # Append the job details to the list
  all_jobs <- c(all_jobs, list(job_details))

}
  # Find the "Next" button and click on it to move to next page
  Sys.sleep(5)
  next_button <- rm$findElement(using = 'css selector', '[data-testid="pagination-page-next"]')
  next_button$clickElement()
  
}

# Convert list to data frame
rm(indeed_jobs_df)
indeed_jobs_df <- data.frame(matrix(unlist(all_jobs), nrow=length(all_jobs), byrow=TRUE))

#set column  names: 
colnames(indeed_jobs_df) <- c("Job Title", "Company", "Location", "Short Description", "Job URL")

#Export dataset as a CSV
write.csv(indeed_jobs_df, "indeed_jobs_df.csv", row.names = TRUE)





