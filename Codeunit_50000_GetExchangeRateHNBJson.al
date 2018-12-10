codeunit 50000 "Get Exchange Rate"
{
    trigger OnRun()
    begin
        SetDateForExchangeRateList(Today, '0D', 0);
    end;

    var
        UpdateHistoryData: Option "Update Existing","Insert Missing";

    procedure SetDateForExchangeRateList(StartDate: Date; DateFormula: Text; newUpdateHistoryData: Option "Update Existing","Insert Missing")
    var
        EndDate: Date;
        CurrentDate: Date;
    begin

        UpdateHistoryData := newUpdateHistoryData;

        EndDate := CalcDate(DateFormula, StartDate);
        CurrentDate := StartDate;
        repeat
            if CurrentDate <> StartDate then
                CurrentDate := CalcDate('-1D', CurrentDate)
            else CurrentDate := CalcDate('-1D', StartDate);

            GetExchangeRateJsonText(CurrentDate);

        until CurrentDate = EndDate;
    end;

    local procedure FormatCurrentDate(CurrentDate: Date) FormatedDate: Text;
    var
        Day: integer;
        Month: Integer;
        Year: Integer;
    begin
        Day := Date2DMY(CurrentDate, 1);
        Month := Date2DMY(CurrentDate, 2);
        Year := Date2DMY(CurrentDate, 3);

        EXIT(Format(Year) + '-' + Format(Month) + '-' + Format(Day));
    end;

    local procedure GetExchangeRateJsonText(CurrentDate: Date)
    var
        HttpClient: HttpClient;
        ResponseMessage: HttpResponseMessage;
        JsonText: Text;
    begin

        if not HttpClient.Get('http://api.hnb.hr/tecajn/v1?datum=' + FormatCurrentDate(CurrentDate), ResponseMessage) then begin
            Error('The call to the web service failed');
        end;

        if not ResponseMessage.IsSuccessStatusCode() then begin
            Error('The web service returned an error message:\\' +
            'Status code: %1\' +
            'Description: %2', ResponseMessage.HttpStatusCode,
            ResponseMessage.ReasonPhrase);
        end;

        ResponseMessage.Content.ReadAs(JsonText);

        ReadFromJsonText(JsonText);

    end;

    local procedure ReadFromJsonText(jsonText: Text)
    var
        JsonToken: JsonToken;
        JsonValue: JsonValue;
        JsonArray: JsonArray;
        JsonObject: JsonObject;
        i: Integer;

        CurrentDate: Date;
    begin
        if not JsonArray.ReadFrom(JsonText) then begin
            Error('Invalid response, expected an JSON array as root object');
        end;

        for i := 0 to JsonArray.Count - 1 do begin
            JsonArray.get(i, JsonToken);
            JsonObject := JsonToken.AsObject;

            CheckDataForInsert(JsonObject);
        end;
    end;

    local procedure CheckDataForInsert(JsonObject: JsonObject)
    var
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        ExchangeRateDate: Date;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyCode := GetJsonToken(JsonObject, 'Valuta').AsValue.AsCode;
        CurrencyFactor := GetJsonToken(JsonObject, 'Srednji za devize').AsValue.AsDecimal;
        ExchangeRateDate := GetJsonToken(JsonObject, 'Datum primjene').AsValue.AsDate;

        if not Currency.Get(CurrencyCode) then
            exit;

        case UpdateHistoryData of
            UpdateHistoryData::"Update Existing":
                begin
                    IF CurrencyExchangeRate.Get(CurrencyCode, ExchangeRateDate) then
                        UpdateExchangeRate(CurrencyCode, CurrencyFactor, ExchangeRateDate);
                end;
            UpdateHistoryData::"Insert Missing":
                begin
                    IF NOT CurrencyExchangeRate.Get(CurrencyCode, ExchangeRateDate) then
                        InsertExchangeRates(CurrencyCode, CurrencyFactor, ExchangeRateDate);
                end;
        END;
    end;

    local procedure InsertExchangeRates(CurrencyCode: code[10]; CurrencyFactor: decimal; ExchangeRateDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Init;
        CurrencyExchangeRate.Validate("Currency Code", CurrencyCode);
        CurrencyExchangeRate.Validate("Starting Date", ExchangeRateDate);
        CurrencyExchangeRate.Insert;

        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyFactor);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyFactor);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure UpdateExchangeRate(CurrencyCode: code[10]; CurrencyFactor: decimal; ExchangeRateDate: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.Get(CurrencyCode, ExchangeRateDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyFactor);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyFactor);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure GetJsonToken(jsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken;
    begin
        if not jsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    local procedure SelectJsonToken(jsonObject: JsonObject; Path: text) JsonToken: JsonToken;
    begin
        if not jsonObject.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;

}