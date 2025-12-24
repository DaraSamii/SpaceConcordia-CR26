
// **Define Parameters for Mesh Dimensions**
xMin -10;
xMax 30;

yMin -10;
yMax  10;

zMin -10;
zMax  10;


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