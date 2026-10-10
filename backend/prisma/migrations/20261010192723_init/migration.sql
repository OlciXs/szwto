-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Monument" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "Monument_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserVisited" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "monumentId" INTEGER NOT NULL,
    "visitedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserVisited_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Monument_name_key" ON "Monument"("name");

-- CreateIndex
CREATE UNIQUE INDEX "UserVisited_userId_monumentId_key" ON "UserVisited"("userId", "monumentId");

-- AddForeignKey
ALTER TABLE "UserVisited" ADD CONSTRAINT "UserVisited_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserVisited" ADD CONSTRAINT "UserVisited_monumentId_fkey" FOREIGN KEY ("monumentId") REFERENCES "Monument"("id") ON DELETE CASCADE ON UPDATE CASCADE;
