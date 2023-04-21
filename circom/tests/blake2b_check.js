var blake2b = require('blake2b')
const wasm_tester = require("circom_tester").wasm;
const fs = require('fs');
const chai = require("chai");
const assert = chai.assert;

async function main() { 
    var output = new Uint8Array(32)
    var input = Buffer.from('hello')

    console.log('hash:', blake2b(output.length).update(input).digest('hex'))

    var myBuffer = [];
    
    for (var i = 0; i < input.length; i++) {
        myBuffer.push(input[i].toString(2).padStart(8, '0').split('').map(Number).reverse())
    }

    console.log(myBuffer)

    const circuit = await wasm_tester("./circuits/main_blake2b.circom");
    await circuit.loadConstraints();

    const inputjson = {
        "in": myBuffer,
    }
    fs.writeFileSync('./circuits/.output/input.json', JSON.stringify(inputjson));

    const witness = await circuit.calculateWitness(inputjson);
    console.log(witness);

    await circuit.checkConstraints(witness);

}

main()