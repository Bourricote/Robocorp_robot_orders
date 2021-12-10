*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${url}=    Ask for csv url
    Open the robot order website
    Download the csv file    ${url}
    Fill the orders and get the receipts using the data from the csv file
    Create ZIP for receipts
    [Teardown]     Close Browser


*** Keywords ***
Ask for csv url
    Add icon      Warning
    Add text      Please provide the url for the csv file
    Add text input    url    label=url csv file
    ${csv_url}=    Run dialog
    Return From Keyword    ${csv_url}[url]

Open the robot order website
    ${url}=     Get Secret     robotOrderUrl
    Open Available Browser    ${url}[url]
    
Consent
    Click Button    class:btn-dark

Download the csv file
    [Arguments]    ${csv_url}
        Download    ${csv_url}    overwrite=True

Fill form for one order
    [Arguments]    ${order}
        Select From List By Value    head    ${order}[Head]
        Select Radio Button    body    id-body-${order}[Body]  
        Input Text    css:input[type="number"]    ${order}[Legs]
        Input Text    address    ${order}[Address]  
        Click Button   preview
        Wait Until Keyword Succeeds  5x  200ms  Click Order

Click Order 
    Click Button   order
    Element Should Be Visible    receipt

Fill the orders and get the receipts using the data from the csv file
    ${orders}=     Read table from CSV    orders.csv  header=True
    FOR    ${order}    IN    @{orders}
        Consent
        Fill form for one order    ${order}
        Collect the order to pdf    ${order}[Order number]
        Click Button    order-another
    END

Collect the order to pdf
    [Arguments]    ${order_number}
        ${pdf}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}order_${order_number}.pdf
        ${screenshot}=     Set Variable    ${OUTPUT_DIR}${/}robot_preview.png
        ${receipt}=    Get Element Attribute    receipt    outerHTML
        Screenshot    css:div#robot-preview-image    ${screenshot}
        ${files}=     Create List    ${screenshot}:format=Letter 
        Html To Pdf    ${receipt}    ${pdf}
        Open Pdf    ${pdf}
        Add Files To Pdf    ${files}    ${pdf}    append=True
        Close Pdf    ${pdf}

Create ZIP for receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts.zip