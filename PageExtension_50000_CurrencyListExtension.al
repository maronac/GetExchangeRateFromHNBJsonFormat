pageextension 50000 "Currencies extension" extends Currencies
{
    actions
    {
        addlast(Creation)
        {
            group("Get Exchange Rate")
            {
                Action(GetExchangeRateFromHNB)
                {
                    ApplicationArea = All;
                    CaptionML = ENU = 'Get exchange rate form HNB';

                    trigger OnAction();
                    var
                        GetExchangeRateFromHNBDialog: Page 50000;
                    begin
                        Clear(GetExchangeRateFromHNBDialog);
                        GetExchangeRateFromHNBDialog.Run();
                    end;
                }
            }
        }
    }
}