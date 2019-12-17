import { shuffle, sort, getProperty, add } from "./utils";
import "./polyfill";

const createRankedItem = (item, index) => ({
    item, score: 1, eliminatedBy: null, finalPosition: null, id: index
})

export const getResult = (state) => {
    return sort(state.items, (itemA, itemB) => itemA.finalPosition - itemB.finalPosition)
}

export const initialize = (listToRank, isHighestFirst) => {
    return {
        items: shuffle(listToRank.map(createRankedItem)),
        currentPosition: isHighestFirst ? 1 : listToRank.length,
        finished: false
    }
}

export const next = (itemsInMatchup, isHighestFirst) => state => {
    const candidates = state.items.filter( item => item.eliminatedBy === null && item.finalPosition === null );

    if (candidates.length === 0){
        state.finished = true;
        state.candidates = [];
        return;        
    }

    if (candidates.length > 1){
        candidates.sort((itemA, itemB) => itemB.score - itemA.score );
        state.candidates = candidates.splice(0, itemsInMatchup);
        return ;
    }

    resolveLastItem(state, candidates[0], isHighestFirst);

    return next(itemsInMatchup, isHighestFirst)(state);    
}

export const pickBest = (best, others) => state => {
    state.items.forEach(item => {
        if (!!others.find(other => other.id === item.id)){
            item.eliminatedBy = best.id;
            return;
        }

        if (best.id === item.id){
            item.score = others.map(getProperty("score")).reduce(add, item.score);
        }
    })
}

export const order = list => state => {
    resolveOrder(state, list.last);
}

const resolveOrder = (state, last) => {
    state.items.forEach( item => {
        if (item === last.value){
            item.eliminatedBy = last.previous !== null ? last.previous.id : null;
            item.score = last.next ? last.value.score + last.next.value.score : last.value.score;
            return;
        }
    })
    
    if (last.previous === null) {
        return;
    }

    return resolveOrder(state, last.previous);
}

const resolveLastItem = (state, last, isHighestFirst) => {
    state.items.forEach(item => {
        if (last.id === item.id){
            item.finalPosition = state.currentPosition
            return;
        }

        if (item.eliminatedBy === last.id) {
            item.eliminatedBy = null;
            return 
        }
    });
    state.currentPosition = state.currentPosition + (isHighestFirst ? 1 : -1);
}