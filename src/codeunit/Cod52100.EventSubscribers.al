codeunit 52100 "H2O Event Subscribers"
{
    SingleInstance = true;
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeCreateDimensionsFromValidateBillToCustomerNo, '', false, false)]
    local procedure "Sales Header_OnBeforeCreateDimensionsFromValidateBillToCustomerNo"(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        SalesHeader.Validate("Work Order Type Code", SalesHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnShowDocDimOnBeforeUpdateSalesLines, '', false, false)]
    local procedure "Sales Header_OnShowDocDimOnBeforeUpdateSalesLines"(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Work Order Type Code", SalesHeader."Shortcut Dimension 2 Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterValidateShortcutDimCode, '', false, false)]
    local procedure "Sales Header_OnAfterValidateShortcutDimCode"(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        SalesHeader.Validate("Work Order Type Code", SalesHeader."Shortcut Dimension 2 Code")
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterSalesLineInsert(var Rec: Record "Sales Line")
    var
        GeneralFunctions: Codeunit "H2O General Functions";
        TimeKeepingTableRec: Record "H2O Time Keeping Table";
    begin
        if SalesPostBoolean_Grec then
            exit;
        IF Rec.Type = Rec.Type::Resource then
            If Res.get(Rec."No.") then begin
                Rec.validate("Work Type Code", Res."Work Type Code");
                Rec.validate("WO Supervisor", Res.Supervisor);
                Rec.validate("Resource Type", Res.Type);
                TimeKeepingTableRec.SetRange("Document Type", Rec."Document Type");
                TimeKeepingTableRec.SetRange("Document No.", Rec."Document No.");
                TimeKeepingTableRec.SetRange("Line No.", Rec."Line No.");
                if TimeKeepingTableRec.FindFirst() then
                    Error('Time Keeping Record already exists for Work Order %1 with Line No. %2', Rec."Document No.", Rec."Line No.");

                GeneralFunctions.InsertRecordInTimeKeepingTable(Rec);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterSalesLineModify(var Rec: Record "Sales Line")
    var
        GeneralFunctions: Codeunit "H2O General Functions";
    begin
        if SalesPostBoolean_Grec then
            exit;
        GeneralFunctions.ModifyRecordInTimeKeepingTable(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteSalesLine(var Rec: Record "Sales Line")
    var
        TimeKeepingTableRec: Record "H2O Time Keeping Table";
        SalesHeader: Record "Sales Header";
    begin
        if SalesPostBoolean_Grec then
            exit;
        if SalesHeader.Get(Rec."Document Type", Rec."Document No.") and SalesHeader."OK To Delete" then
            exit;
        IF Rec.Type = Rec.Type::Resource then
            If Res.get(Rec."No.") then begin
                TimeKeepingTableRec.SetRange("Document Type", Rec."Document Type");
                TimeKeepingTableRec.SetRange("Document No.", Rec."Document No.");
                TimeKeepingTableRec.SetRange("Line No.", Rec."Line No.");
                if TimeKeepingTableRec.FindFirst() then
                    Error('Cannot delete Work Order %1 with Line No. %2, Already entry exists in TimeKeeping Table', Rec."Document No.", Rec."Line No.");
            end;


    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforePostSalesDoc, '', false, false)]
    local procedure OnBeforePostSalesDoc()
    begin
        SalesPostBoolean_Grec := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnAfterPostSalesDoc, '', false, false)]
    local procedure OnAfterPostSalesDoc()
    begin
        Clear(SalesPostBoolean_Grec);
    end;

    var
        Res: Record Resource;
        SalesPostBoolean_Grec: Boolean;
}