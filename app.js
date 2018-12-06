import RankingTool from "./rankingTool";

const NUMBER_OF_ITEMS = 50;
const ITERATIONS = 1000000;

const generateItems = (numberOfItems) => {
    return new Array(numberOfItems).fill(0).map((e, i) => "" + i);
}

let totalIterations = 0;
let minIterations = null;
const startTime = process.hrtime();
for (let i = 0; i < ITERATIONS; i++) {
    let iterations = 0;
    let engine = new RankingTool(generateItems(NUMBER_OF_ITEMS));
    while(true){
        iterations++;
        let currentMatchup = engine.next(); 
        if (!currentMatchup){
            break;
        }
    
        let result = Math.floor(Math.random() * 2);
        engine.resolveMatchup(currentMatchup[result], currentMatchup[1-result]);
    }
    
    totalIterations += iterations;
    (minIterations === null || iterations < minIterations) && (minIterations = iterations);
}

const endTime = process.hrtime();

console.log(totalIterations / ITERATIONS);
console.log(minIterations);
console.log("-------------");
console.log(endTime);
console.log(startTime);
const totalTime = (endTime[0] - startTime[0]) * 1000000000 + endTime[1] - startTime[1];

console.log(totalTime / 1000000 / ITERATIONS);