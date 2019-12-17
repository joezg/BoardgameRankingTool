import RankingTool from "./OldRankingTool";
import { getRandomInt, shuffle } from "./utils";

const NUMBER_OF_ITEMS = 256;
const ITERATIONS = 100000;
const ITEMS_IN_MATCHUP = 2;
const USE_ORDER = false;
const HIGHEST_FIRST = false;
const LOG_MATCHUPS = false;
const LOG_RESULT = false;
const EDGE_CASE = false;
const WORST_CASE = true;

const generateItems = (numberOfItems) => {
    return new Array(numberOfItems).fill(0).map((e, i) => "" + i);
}

let totalIterations = 0;
let minIterations = null;
let maxIterations = null;
const startTime = process.hrtime();
for (let i = 0; i < ITERATIONS; i++) {
    let iterations = 0;
    let engine = new RankingTool(generateItems(NUMBER_OF_ITEMS), { highestFirst: HIGHEST_FIRST, itemsInMatchup: ITEMS_IN_MATCHUP });
    while(true){
        let currentMatchup = engine.next(); 
        if (!currentMatchup){
            break;
        }
        iterations++;
    
        if (USE_ORDER){
            if (EDGE_CASE){
                currentMatchup.sort((itemA, itemB) => (itemB.score - itemA.score) * (WORST_CASE ? 1 : -1));
            } else {
                currentMatchup = shuffle(currentMatchup);
            }
            if (LOG_MATCHUPS){
                console.log("**************")
                console.log(currentMatchup);
                console.log("winner: ordered");
            }
            engine.resolveWithOrder(currentMatchup);
        } else {
            let result = 0;
            if (EDGE_CASE) {
                currentMatchup.sort((itemA, itemB) => (itemB.score - itemA.score) * (WORST_CASE ? 1 : -1));
            } else {
                result = getRandomInt(0, currentMatchup.length -1);
            }
            let winner = currentMatchup[result];
            if (LOG_MATCHUPS){
                console.log("**************")
                console.log(currentMatchup);
                console.log(winner);
            }
            currentMatchup.splice(result, 1)
            engine.resolveWithPickup(winner, ...currentMatchup);
        }


    }

    if (LOG_RESULT){
        console.log("##############")
        console.log(engine.getResult());
        console.log("##############");
    }
    
    totalIterations += iterations;
    (minIterations === null || iterations < minIterations) && (minIterations = iterations);
    (maxIterations === null || iterations > maxIterations) && (maxIterations = iterations);
}

const diffTime = process.hrtime(startTime);

console.log(`average iterations: ${totalIterations / ITERATIONS}`);
console.log(`min iterations: ${minIterations}`);
console.log(`max iterations: ${maxIterations}`);
console.log("-------------");

const totalSeconds = diffTime[0] + diffTime[1] / 1000000000;

console.log(`total time (ms): ${totalSeconds * 1000}`);
console.log(`average time (ms): ${totalSeconds * 1000 / ITERATIONS}`);