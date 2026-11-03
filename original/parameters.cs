
// **Define Parameters for Mesh Dimensions**
xMin -5;//-10;
xMax 10;//30;

yMin -5;//-10;
yMax  5;//10;

zMin -5;//-10;
zMax  5;//10;


//Geometry "OneStage";
Geometry "TwoStage";


// **Define Number of Cells**
maxCellSize 2;

P 101325;
T 300;


Ma      1.8;
gamma   1.4;
R       287.05;


AoA 6.0;

WriteInterval 200;