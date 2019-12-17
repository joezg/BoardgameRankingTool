export const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;

export const shuffle = (arr) => {
    const newArray = [...arr];
    for (let i = newArray.length - 1; i > 0; i--) {
        const j = getRandomInt(0, i);
        [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
};

export const sort = (arr, fn) => {
    return [...arr].sort(fn);
}

export const getProperty = property => item => item[property];
export const add = (first, second) => first + second