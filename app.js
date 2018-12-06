import RankingTool from "./rankingTool";
import { getRandomInt, shuffle } from "./utils";

const NUMBER_OF_ITEMS = 6;
const ITERATIONS = 1;
const ITEMS_IN_MATCHUP = 2;
const USE_ORDER = false;
const HIGHEST_FIRST = false;
const LOG_MATCHUPS = true;
const LOG_RESULT = true;

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
            shuffle(currentMatchup);;
            if (LOG_MATCHUPS){
                console.log("**************")
                console.log(currentMatchup);
                console.log("winner: ordered");
            }
            engine.resolveWithOrder(currentMatchup);
        } else {
            let result = getRandomInt(0, currentMatchup.length -1);
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

const endTime = process.hrtime();

console.log(totalIterations / ITERATIONS);
console.log(minIterations);
console.log(maxIterations);
console.log("-------------");
const totalTime = (endTime[0] - startTime[0]) * 1000000000 + endTime[1] - startTime[1];

console.log(totalTime / 1000000 / ITERATIONS);