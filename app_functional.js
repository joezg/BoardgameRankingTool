import * as RankingTool from "./RankingTool";
import { getRandomInt, shuffle } from "./utils";
import produce from 'immer';

const NUMBER_OF_ITEMS = 8;
const ITERATIONS = 1000;
const ITEMS_IN_MATCHUP = 2;
const USE_ORDER = false;
const HIGHEST_FIRST = true;
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
    let state = RankingTool.initialize(generateItems(NUMBER_OF_ITEMS), HIGHEST_FIRST);
    while(true){
        state = produce(state, RankingTool.next(ITEMS_IN_MATCHUP, HIGHEST_FIRST)); 
        if (state.finished){
            break;
        }
        iterations++;

        let currentMatchup = [...state.candidates];
    
        if (USE_ORDER){
            if (EDGE_CASE){
                currentMatchup.sort((itemA, itemB) => (itemB.score - itemA.score) * (WORST_CASE ? 1 : -1));
            } else {
                shuffle(currentMatchup);
            }
            if (LOG_MATCHUPS){
                console.log("**************")
                console.log(currentMatchup);
                console.log("winner: ordered");
            }
            const ordered = new DoubleLinkedList();
            currentMatchup.forEach(ordered.append);
            state = produce(state, RankingTool.order(ordered));
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
            state = produce(state, RankingTool.pickBest(winner, currentMatchup));
        }
    }

    if (LOG_RESULT){
        console.log("##############")
        console.log(RankingTool.getResult(state));
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