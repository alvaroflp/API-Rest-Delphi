program Backend;

{$APPTYPE CONSOLE}

{$R *.res}

uses Horse, System.JSON, System.SysUtils, Horse.Commons,
Horse.BasicAuthentication, Horse.Jhonson, Horse.Compression;

var
  App: THorse;
  Users: TJSONArray;

begin
  //instancia a API Horse usando a porta 9000 ou a definir
  App := THorse.Create(9000);
  //usa o midleware de compressao antes do jhonson
  App.Use(Compression());

  App.Use(Jhonson);

  //autenticação de usuario usando o basic auth
  App.Use(HorseBasicAuthentication(
    function(const AUsername, APassword: string): Boolean
    begin
      Result := AUsername.Equals('alvaro') and APassword.Equals('senha123');
    end));

  Users := TJSONArray.Create;

  //envia um JSON usando GET
  App.Get('/users',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin
        Res.Send<TJSONAncestor>(Users.Clone);
      end);

  //recebe um JSON usando POST
  App.Post('/users',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      var
        User: TJSONObject;
      begin
        User := Req.Body<TJSONObject>.Clone as TJSONObject;
        Users.AddElement(User);
        //define status code usando Horse.Commons ao invés de repassar manualmente o status
        Res.Send<TJSONAncestor>(User.Clone).Status(THTTPStatus.Created);
      end);

  //deleta um JSON da memória usando DELETE
    //deleta usando URL params
  App.Delete('/users/:id',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      var
        id: Integer;
      begin
        //
        id := Req.Params.Items['id'].ToInteger;
        //usa .free para não dar memory leak
          //Usa o Pred para pegar o índice 0, seria o mesmo com (id - 1)
        Users.Remove(Pred(id)).Free;
        //define status code usando Horse.Commons ao invés de repassar manualmente o status
        Res.Send<TJSONAncestor>(Users.Clone).Status(THTTPStatus.NoContent);
      end);

    //Inicializa a API
    App.Start;
end.
