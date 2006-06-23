unit uAIAmmoTests;
interface
uses SDLh, uGears, uConsts;

function TestBazooka(Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
function TestGrenade(Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
function TestShotgun(Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;

type TAmmoTestProc = function (Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
const AmmoTests: array[TAmmoType] of TAmmoTestProc =
                 (
{amGrenade}       TestGrenade,
{amBazooka}       TestBazooka,
{amUFO}           nil,
{amShotgun}       TestShotgun,
{amPickHammer}    nil,
{amSkip}          nil,
{amRope}          nil,
{amMine}          nil,
{amDEagle}        nil,
{amDynamite}      nil
                  );

implementation
uses uMisc, uAIMisc;
const BadTurn = Low(integer);

function Metric(x1, y1, x2, y2: integer): integer;
begin
Result:= abs(x1 - x2) + abs(y1 - y2)
end;

function TestBazooka(Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
var Vx, Vy, r: real;
    rTime: real;
    Score: integer;

    function CheckTrace: integer;
    var x, y, dX, dY: real;
        t: integer;
    begin
    x:= Me.X;
    y:= Me.Y;
    dX:= Vx;
    dY:= -Vy;
    t:= trunc(rTime);
    repeat
      x:= x + dX;
      y:= y + dY;
      dX:= dX + cWindSpeed;
      dY:= dY + cGravity;
      dec(t)
    until TestColl(round(x), round(y), 5) or (t <= 0);
    Result:= RateExplosion(Me, round(x), round(y), 101);
    if Result = 0 then Result:= - Metric(Targ.X, Targ.Y, round(x), round(y)) div 64
    end;

begin
Time:= 0;
rTime:= 10;
Result:= BadTurn;
repeat
  rTime:= rTime + 100 + random*250;
  Vx:= - cWindSpeed * rTime / 2 + (Targ.X - Me.X) / rTime;
  Vy:= cGravity * rTime / 2 - (Targ.Y - Me.Y) / rTime;
  r:= sqr(Vx) + sqr(Vy);
  if r <= 1 then
     begin
     Score:= CheckTrace;
     if Result <= Score then
        begin
        r:= sqrt(r);
        Angle:= DxDy2AttackAngle(Vx, Vy);
        Power:= round(r * cMaxPower);
        Result:= Score
        end;
     end
until (rTime >= 5000)
end;

function TestGrenade(Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
const tDelta = 24;
var Vx, Vy, r: real;
    Score: integer;
    TestTime: Longword;

    function CheckTrace: integer;
    var x, y, dY: real;
        t: integer;
    begin
    x:= Me.X;
    y:= Me.Y;
    dY:= -Vy;
    t:= TestTime;
    repeat
      x:= x + Vx;
      y:= y + dY;
      dY:= dY + cGravity;
      dec(t)
    until TestColl(round(x), round(y), 5) or (t = 0);
    if t < 50 then Result:= RateExplosion(Me, round(x), round(y), 101)
              else Result:= Low(integer)
    end;

begin
Result:= BadTurn;
TestTime:= 0;
repeat
  inc(TestTime, 1000);
  Vx:= (Targ.X - Me.X) / (TestTime + tDelta);
  Vy:= cGravity*((TestTime + tDelta) div 2) - (Targ.Y - Me.Y) / (TestTime + tDelta);
  r:= sqr(Vx) + sqr(Vy);
  if r <= 1 then
     begin
     Score:= CheckTrace;
     if Result < Score then
        begin
        r:= sqrt(r);
        Angle:= DxDy2AttackAngle(Vx, Vy);
        Power:= round(r * cMaxPower);
        Time:= TestTime;
        Result:= Score
        end;
     end
until (TestTime = 5000)
end;

function TestShotgun(Me: PGear; Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
var Vx, Vy, x, y: real;
begin
if Metric(round(Me.X), round(Me.Y), Targ.X, Targ.Y) < 80 then
   begin
   Result:= BadTurn;
   exit
   end;
Time:= 0;
Power:= 1;
Vx:= (Targ.X - Me.X)/1024;
Vy:= (Targ.Y - Me.Y)/1024;
x:= Me.X;
y:= Me.Y;
Angle:= DxDy2AttackAngle(Vx, -Vy);
repeat
  x:= x + vX;
  y:= y + vY;
  if TestColl(round(x), round(y), 2) then
     begin
     Result:= RateExplosion(Me, round(x), round(y), 25) * 2;
     if Result = 0 then Result:= - Metric(Targ.X, Targ.Y, round(x), round(y)) div 64;
     exit
     end
until (abs(Targ.X - x) + abs(Targ.Y - y) < 4) or (x < 0) or (y < 0) or (x > 2048) or (y > 1024);
Result:= BadTurn
end;

end.
