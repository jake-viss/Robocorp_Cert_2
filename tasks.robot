*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders_url}=    Ask for orders link
    ${orders}=    Get orders    ${orders_url}
    FOR    ${row}    IN    @{orders}
        Close Popup
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Success Dialog

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    website
    Open Available Browser    ${secret}[url]

Ask for orders link
    Add heading    URL Request
    Add text input    URL    label=Please enter the orders.csv URL here.
    ${result}=    Run dialog
    [Return]    ${result}[URL]

Get Orders
    [Arguments]    ${orders_url}
    Download    ${orders_url}    overwrite=True
    @{orders}=    Read table from CSV    orders.csv
    [Return]    @{orders}

Close Popup
    Wait And Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill the form
    [Arguments]    ${row}
    ${body}=    Convert To Integer    ${row}[Body]
    # Selects the head
    Select From List By Value    id:head    ${row}[Head]
    # Select the Body radio button
    Click Element    id-body-${body}
    # Input text for leg number
    Input Text    xpath:/html/body/div[1]/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    # Input text for Address
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Wait Until Keyword Succeeds    10x    1s    Submit the order until success

Submit the order until success
    Click Button    id:order
    Element Should Be Visible    id:order-completion

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${order_receipt}=    Get Element Attribute    id:order-completion    outerHTML
    ${pdf_path}=    Set Variable    ${OUTPUT_DIR}${/}Receipts${/}receipt${order_number}.pdf
    Html To Pdf    ${order_receipt}    ${pdf_path}
    [Return]    ${pdf_path}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:robot-preview-image
    ${screenshot_path}=    Set Variable    ${OUTPUT_DIR}${/}Screenshots${/}screenshot${order_number}.png
    Capture Element Screenshot    id:robot-preview-image    ${screenshot_path}
    [Return]    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}    #${OUTPUT_DIR}${/}Receipts${/}receipt${order_number}.pdf
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}

Go to order another robot
    Click Button    id:order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}Receipts    ${zip_file_name}

Success Dialog
    Add icon    Success
    Add heading    Your .ZIP file has been created.
    Run dialog    title=Success
