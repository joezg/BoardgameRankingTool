import RankingTool from "./rankingTool";

const NUMBER_OF_ITEMS = 30;
const ITERATIONS = 1000000;

const generateItems = (numberOfItems) => {
    return new Array(numberOfItems).fill(0).map((e, i) => "" + i);
}

let totalIterations = 0;
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
}

console.log(totalIterations / ITERATIONS);