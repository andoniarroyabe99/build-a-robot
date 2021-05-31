*** Settings ***
Documentation   Program to build robots
...             and capture the info
Library         RPA.Archive
Library         RPA.Browser.Selenium
Library         RPA.FileSystem
Library         RPA.HTTP
Library         RPA.PDF
Library         RPA.Robocloud.Secrets
Library         RPA.Tables


*** Variables ***
${excelurl}     https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY_AMOUNT}    3x
${GLOBAL_RETRY_INTERVAL}  3s
${path}         /html[1]/body[1]/div[1]/div[1]/div[1]/div[1]/div[1]/form[1]/div[1]/select[1]
${text}         BY USING THIS ORDER FORM, I GIVE UP ALL MY CONSTITUTIONAL RIGHTS FOR THE BENEFIT OF ROBOTSPAREBIN INDUSTRIES INC.
${recibopdf}    ${OUTPUT_DIR}${/}pdf${/}receipt
${reciboimg}    ${OUTPUT_DIR}${/}img${/}receipt

*** Keywords ***
Open Browser
    ${secret}=    Get Secret    credentials
    Open Available Browser  ${secret}[url]
    Maximize Browser Window

*** Keywords ***
Download File
    Download  ${excelurl}  overwrite=True  target_file=${CURDIR}

*** Keywords ***
Handle Modal
    Click Button  OK

*** Keywords ***
Saving Screenshots
    Create Directory            ${CURDIR}/output/screenshots
    Set Screenshot Directory    ${CURDIR}/output/screenshots

*** Keywords ***
Read File
    ${tabla}=   Read Table From Csv  orders.csv  ${CURDIR}  delimiters=,
    FOR  ${fila}  IN  @{tabla}
        Wait Until Keyword Succeeds  ${GLOBAL_RETRY_AMOUNT}  ${GLOBAL_RETRY_INTERVAL}  Fill Form  ${fila}
        Wait Until Keyword Succeeds  ${GLOBAL_RETRY_AMOUNT}  ${GLOBAL_RETRY_INTERVAL}  PDF        ${fila}
        Another One
    END

*** Keywords ***
Fill Form
    [Arguments]  ${fila} 
    Wait Until Element Contains  class=form-group  1.
    ${numhead}=        Convert To Integer    ${fila}[Head]
    Click Element      xpath=${path}/option[${numhead + 1}]
    Click Element      id=id-body-${fila}[Body]
    Input Text         class=form-control    ${fila}[Legs]
    Input Text         id=address    ${fila}[Address]
    Click Button       Preview


*** Keywords ***
PDF
    [Arguments]  ${fila}
    Log  ${fila}
    Wait Until Element Is Visible    id=order
    sleep  1s
    Click Element      id=order
    Wait Until Element Is Visible    id=receipt
    ${receipt_html}=   Get Element Attribute    id=receipt    outerHTML
    Html to Pdf        ${receipt_html}    ${recibopdf}${fila}[Order number].pdf
    Wait Until Element Is Visible    id=robot-preview-image
    ${screenshot}=     Capture Element Screenshot   id=robot-preview-image  ${reciboimg}${fila}[Order number].png
    Open Pdf           ${recibopdf}${fila}[Order number].pdf
    Add Watermark Image To Pdf  ${screenshot}  ${recibopdf}${fila}[Order number].pdf
    Close All Pdfs

*** Keywords ***
Another One
    Click Button       id=order-another
    Wait Until Element Contains  class=modal-body  ${text}
    Handle Modal

*** Keywords ***
Create Directories
    Create Directory   ${OUTPUT_DIR}/pdf
    Create Directory   ${OUTPUT_DIR}/img

*** Keywords ***
Zip
    Archive Folder With Zip  ${OUTPUT_DIR}/pdf  pdf.zip

*** Tasks ***
Build-a-robot
    Open Browser
    Create Directories
    Download File
    Handle Modal
    Saving Screenshots
    Read File
    Zip
    [Teardown]  Close All Browsers
