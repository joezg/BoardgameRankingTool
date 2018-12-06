import RankingTool from "./rankingTool";
import { getRandomInt } from "./utils";

const NUMBER_OF_ITEMS = 30;
const ITERATIONS = 100000;
const ITEMS_IN_MATCHUP = 2;

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
        let currentMatchup = engine.next(ITEMS_IN_MATCHUP); 
        if (!currentMatchup){
            break;
        }
    
        let result = getRandomInt(0, currentMatchup.length -1);
        let winner = currentMatchup[result];
        currentMatchup.splice(result, 1)
        engine.resolveMatchup(winner, ...currentMatchup);
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