import Foundation

let bigTree: RedBlackTree<Int> =
    .node(.black, 9,
          .node(.red, 5,
                .node(.black, 1, .empty, .node(.red, 4, .empty, .empty)),
                .node(.black, 8, .empty, .empty)),
          .node(.red, 12,
                .node(.black, 11, .empty, .empty),
                .node(.black, 16,
                      .node(.red, 14, .empty, .empty),
                      .node(.red, 17, .empty, .empty))))

//print(bigTree.description)

let treeSize = 50
print("=== Balanced tree 1 to \(treeSize) ===")
var set = RedBlackTree<Int>.empty
for i in (1 ... treeSize).shuffled() {
    set.insert(i)
}

print(set)
