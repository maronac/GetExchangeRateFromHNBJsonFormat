page 50000 "Get Exchange Rate Dialog"
{
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("Start Date"; StartDate)
                {
                    ApplicationArea = All;
                }
                field("Date Formula"; DateForumla)
                {
                    ApplicationArea = All;
                }
                field("Update History Data"; UpdateHistoryData)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        StartDate := Today();
        DateForumla := '0D';
        UpdateHistoryData := UpdateHistoryData::"Insert Missing";
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GetExchageRateFromHNBJson: Codeunit 50000;
    begin
        Clear(GetExchageRateFromHNBJson);
        GetExchageRateFromHNBJson.SetDateForExchangeRateList(StartDate, DateForumla, UpdateHistoryData);
    end;

    var
        StartDate: Date;
        DateForumla: Text;
        UpdateHistoryData: Option "Update Existing","Insert Missing";

}