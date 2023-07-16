unit Database.Tipos;

interface

uses
  Data.DB, System.Generics.Collections, System.Variants,
  System.SysUtils,

  FireDac.DApt, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Phys, FireDAC.Comp.Client,
  FireDAC.Comp.DataSet, FireDac.Comp.Script, FireDAC.Stan.Param,
  FireDAC.Comp.ScriptCommands, FireDAC.Stan.Util;

type
  TQuery = FireDAC.Comp.Client.TFDQuery;
  TStoredProc = FireDAC.Comp.Client.TFDStoredProc;
  TMemTable = FireDAC.Comp.Client.TFDMemTable;
  TScript = FireDac.Comp.Script.TFDScript;
  TParams = FireDAC.Stan.Param.TFDParams;
  TConnection = FireDAC.Comp.Client.TFDConnection;
  TDataSet = Data.DB.TDataSet;


  TParamsConsultaBDValue = record
    FValor: variant;
    FTipo: TFieldType; // ftString, ftInteger, ftFloat, ftDateTime
  end;

  TConnectionDefDriverParams = record
  private
    FDriverDefName: string;
    FVendorLib: string;
    procedure SetDriverDefName(const Value: string);
    procedure SetVendorLib(const Value: string);

  public
    property DriverDefName: string read FDriverDefName write SetDriverDefName;
    property VendorLib: string read FVendorLib write SetVendorLib;
  end;

  TConnectionDefParams = record
  private
    FConnectionDefName: string;
    FServer: string;
    FDatabase: string;
    FUserName: string;
    FPassword: string;
    FLocalConnection: Boolean;

    procedure SetConnectionDefName(const Value: string);
    procedure SetDatabase(const Value: string);
    procedure SetLocalConnection(const Value: Boolean);
    procedure SetPassword(const Value: string);
    procedure SetServer(const Value: string);
    procedure SetUserName(const Value: string);

  public
    property ConnectionDefName: string read FConnectionDefName write SetConnectionDefName;
    property Server: string read FServer write SetServer;
    property Database: string read FDatabase write SetDatabase;
    property UserName: string read FUserName write SetUserName;
    property Password: string read FPassword write SetPassword;
    property LocalConnection: Boolean read FLocalConnection write SetLocalConnection;
  end;

  TConnectionDefPoolParams = record
  private
    FPooled: Boolean;
    FPoolMaximumItems: Integer;
    FPoolCleanupTimeout: Integer;
    FPoolExpireTimeout: Integer;
    procedure SetPoolCleanupTimeout(const Value: Integer);
    procedure SetPoolExpireTimeout(const Value: Integer);
    procedure SetPoolMaximumItems(const Value: Integer);
    procedure SetPooled(const Value: Boolean);

  public
    property Pooled: Boolean read FPooled write SetPooled;
    property PoolMaximumItems: Integer read FPoolMaximumItems write SetPoolMaximumItems;
    property PoolCleanupTimeout: Integer read FPoolCleanupTimeout write SetPoolCleanupTimeout;
    property PoolExpireTimeout: Integer read FPoolExpireTimeout write SetPoolExpireTimeout;
  end;

type
 TParamList = class
  private
    fLista: TObjectDictionary<string, TParamsConsultaBDValue>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    class function CreateNew: TParamList;
    procedure SetParams(pQuery: TFDQuery);
    function Adiciona(pNomPar: string; pType: TFieldType; pValue: variant): TParamList;
    function Clone: TParamList;
    function Value(pNomPar: string): Variant;
    function ToString: string;
    class function VarVoidToNull(Value: Variant): Variant;
    class function VarToInt(Value: Variant): Integer;
    class function VarToString(Value: Variant): String;
    class function VarToFloat(Value: Variant): Double;
    class function VarToDateTime(Value: Variant): TDateTime;
    property Lista: TObjectDictionary<string, TParamsConsultaBDValue> read fLista;
  end;

implementation

{ TParamList }

function TParamList.Adiciona(pNomPar: string; pType: TFieldType;
  pValue: variant): TParamList;
var
  r: TParamsConsultaBDValue;
begin
  r.FValor := pValue;
  r.FTipo  := pType;
  fLista.Add(pNomPar, r);
  result := Self;
end;

procedure TParamList.Clear;
begin
  fLista.Clear;
end;

function TParamList.Clone: TParamList;
var
  Key: string;
begin
  if not assigned(Self) then
     result:= nil
  else begin
    result := TParamList.Create;
    for Key in Self.fLista.Keys do
      result.fLista.Add(Key,fLista.Items[Key]);
  end;
end;

constructor TParamList.Create;
begin
  fLista := TObjectDictionary<string, TParamsConsultaBDValue>.Create;
end;

class function TParamList.CreateNew: TParamList;
begin
  result := TParamList.Create;
end;

destructor TParamList.Destroy;
begin
  fLista.Clear;
  fLista.Free;
  inherited;
end;

procedure TParamList.SetParams(pQuery: TFDQuery);
var
  Key: string;
begin
  for Key in Self.fLista.Keys do
  begin
    pQuery.ParamByName(Key).DataType := fLista.Items[Key].FTipo;
    pQuery.ParamByName(Key).Value := fLista.Items[Key].FValor;
  end;
end;

function TParamList.ToString: string;
var
  Key: string;
begin
  result:= '';
  for Key in Self.fLista.Keys do begin
      if result <> ''
      then result := result + '; ';
      result := result + Key + '=' + '"'+ fLista.Items[Key].FValor + '"';
  end;
end;

function TParamList.Value(pNomPar: string): Variant;
var
  Key: string;
begin
  result:= null;
  for Key in Self.fLista.Keys do
      if Uppercase(Key) = Uppercase(pNomPar) then begin
          case fLista.Items[Key].FTipo of
            ftString:   result := fLista.Items[Key].FValor;
            ftInteger:  result := Integer(fLista.Items[Key].FValor); // aquitem
            ftFloat:    result := fLista.Items[Key].FValor;
            ftDateTime: result := fLista.Items[Key].FValor;
          else
            result := fLista.Items[Key].FValor;
          end;
          break;
      end;
end;

class function TParamList.VarToDateTime(Value: Variant): TDateTime;
begin
  if (Value = Null) then
     Result := 0
  else Result := Value
end;

class function TParamList.VarToFloat(Value: Variant): Double;
begin
  if (Value = Null) then
     Result := 0
  else Result := Value;
end;

class function TParamList.VarToInt(Value: Variant): Integer;
begin
  if (Value = Null) then
     Result := 0
  else Result := Value;
end;

class function TParamList.VarToString(Value: Variant): String;
begin
  if (Value = Null) then
     Result := ''
  else Result := Value;
end;

class function TParamList.VarVoidToNull(Value: Variant): Variant;
var
  ValueModf : Variant;
  mVarType : Word;
begin
  ValueModf := Value;
  mVarType  := VarType(ValueModf);

  if (mVarType = varString) or (mVarType = varUString) then
  begin
    if (Value = '') then
     ValueModf := null;
  end
  else
  if ((mVarType = varDate) or (mVarType = varInteger)) then
     if (Value = 0) then
        ValueModf := null;

  Result := ValueModf;
end;

{ TConnectionDefPoolParams }

procedure TConnectionDefPoolParams.SetPoolCleanupTimeout(const Value: Integer);
begin
  FPoolCleanupTimeout:= Value;
end;

procedure TConnectionDefPoolParams.SetPooled(const Value: Boolean);
begin
  FPooled := Value;
end;

procedure TConnectionDefPoolParams.SetPoolExpireTimeout(const Value: Integer);
begin
  FPoolExpireTimeout := Value;
end;

procedure TConnectionDefPoolParams.SetPoolMaximumItems(const Value: Integer);
begin
  FPoolMaximumItems := Value;
end;

{ TConnectionDefParams }

procedure TConnectionDefParams.SetConnectionDefName(const Value: string);
begin
  FConnectionDefName := Value;
end;

procedure TConnectionDefParams.SetDatabase(const Value: string);
begin
  FDatabase := Value;
end;

procedure TConnectionDefParams.SetLocalConnection(const Value: Boolean);
begin
  FLocalConnection := Value;
end;

procedure TConnectionDefParams.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure TConnectionDefParams.SetServer(const Value: string);
begin
  FServer := Value;
end;

procedure TConnectionDefParams.SetUserName(const Value: string);
begin
  FUserName := Value;
end;

{ TConnectionDefDriverParams }

procedure TConnectionDefDriverParams.SetDriverDefName(const Value: string);
begin
  FDriverDefName := Value;
end;

procedure TConnectionDefDriverParams.SetVendorLib(const Value: string);
begin
  FVendorLib := Value;
end;

end.


