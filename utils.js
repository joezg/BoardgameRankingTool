export const getRandomInt = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min;
export const shuffle = (arr) => {
    for (let i = arr.length - 1; i > 0; i--) {
        let ix = getRandomInt(0, i);
        let temp = arr[i];
        arr[i] = arr[ix];
        arr[ix] = temp;
    }
    return arr;
};